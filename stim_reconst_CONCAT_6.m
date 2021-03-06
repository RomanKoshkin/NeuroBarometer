% Compared to stim_reconst_1_PARFOR.m, this code is about twice as
% efficient.

% load('KOS_1+2_80Hz.mat')

% load('KOS_DAS_80Hz.mat')
% load('Merged123_noICA.mat')
% load('Merged123_ICA.mat')
load('/Users/RomanKoshkin/Downloads/EEG_latest/DAS_CH.mat')

% filein = 'Merged456';
% load(['/Volumes/Transcend/NeuroBarometer/' filein '.mat'])

clearvars -except EEG
tic

%% define model parameters:
LAMBDA = 0.03;
len_win_classified =    30;
compute_envelope =      1;
center_normalize =      1;
filtering =             1;
resample = 1;
low_cutoff =            1;
high_cutoff =           30;
DOWNSAMPLE_TO =         64;
% lags start and end:
or = 0;    % kernel origin, ms % ???????????, ??? ??????, ??? ?????
en = 300;

% range of events in the EEG.event struct
% events = [5:64, 75:134, 143:202];     % Merged123
% events = [1:94], [101:192], [197:289] % Merged456
events = [5:64];
events = [1:124]; % DAS_CH.mat

ch_left = find(ismember({EEG.chanlocs.labels}, 'Left_AUX') == 1);
ch_right = find(ismember({EEG.chanlocs.labels},'Right_AUX') == 1);

if center_normalize == 1
    EEG.data = EEG.data-repmat(mean(EEG.data,2),1,size(EEG.data,2));
    EEG.data = EEG.data./std(EEG.data,0, 2);
end
if filtering == 1
    [EEG, ~, ~] = pop_eegfiltnew(EEG, low_cutoff, high_cutoff);
end
if resample == 1
    EEG = pop_resample(EEG, DOWNSAMPLE_TO);
end
Fs = EEG.srate;
if compute_envelope == 1
    EEG.data(ch_left,:) = envelope(EEG.data(ch_left,:));
    EEG.data(ch_right,:) = envelope(EEG.data(ch_right,:));        
end

% initialize an empty struct array with ALL the necessary fields.
% Otherwise the PARFOR loops won't run.
S = struct('type', [], 'code_no', [], 'latency', [],...
    'a_r_left', [], 'a_r_right', []);

ch_left = find(ismember({EEG.chanlocs.labels}, 'Left_AUX') == 1);
ch_right = find(ismember({EEG.chanlocs.labels},'Right_AUX') == 1);
Fs = EEG.srate;

% determine what's right, what's left:
for j = events
    if strcmp(EEG.event(j).type, 'L_Lef_on') == 1 
        S(j).type = 'left';
        S(j).code_no = j;

    end
    if strcmp(EEG.event(j).type, 'L_Rig_on') == 1
        S(j).type = 'right';
        S(j).code_no = j;
    end

    if strcmp(EEG.event(j).type, 'other') == 1
        continue
    end

    if strcmp(EEG.event(j).type, 'L_Lef_off') == 1
        continue
    end

    if strcmp(EEG.event(j).type, 'L_Rig_off') == 1
        continue
    end
end

% get rid of empty rows:
S = S(~cellfun('isempty',{S.code_no}));
%%

% load onset latencies into S.latency:
temp = num2cell([EEG.event([S.code_no]).latency]);
[S.latency] = temp{:};

%% now split the data into two large continuous subsets (attend right, attend left)
att_right = [S(find(ismember({S.type}, 'right'))).code_no];
att_left = [S(find(ismember({S.type}, 'left'))).code_no];

% initialize some vars:
stimLeft_A = [];
stimRight_A = [];

respRight_A = [];
respLeft_A = [];


for i = 1:length(S)
    start = round(EEG.event(i).latency);
    fin = start + 30*EEG.srate-1;
    
    if strcmp(S(i).type, 'right')==1
        stimRight_A = cat(2, stimRight_A, EEG.data(ch_right, start:fin));
        respRight_A = cat(2, respRight_A, EEG.data(1:60, start:fin));
    else
        stimLeft_A = cat(2, stimLeft_A, EEG.data(ch_left, start:fin));
        respLeft_A = cat(2, respLeft_A, EEG.data(1:60, start:fin));
    end
end

stimLeft_A = stimLeft_A';
stimRight_A = stimRight_A';

respRight_A = respRight_A';
respLeft_A = respLeft_A';

% and find the decoders on these large CONCATENATED subsets:
[g_right,t, Lcon_R] =    mTRFtrain(stimRight_A,  respRight_A,    Fs, 1, or, en, LAMBDA);
[g_left,t, Lcon_L] =     mTRFtrain(stimLeft_A,   respLeft_A,     Fs, 1, or, en, LAMBDA);
    
parfor j = 1:length(S) % FOR/PARFOR

    start = round(S(j).latency);
    fin = round(start + len_win_classified*EEG.srate);

    stimLeft = EEG.data(ch_left, start:fin)';
    stimRight = EEG.data(ch_right, start:fin)';

    response = EEG.data(1:60, start:fin)';
   
    
    [~, S(j).a_r_left, ~, ~] = mTRFpredict(stimLeft, response, g_left, Fs, 1, or, en, Lcon_L);
    [~, S(j).a_r_right, ~, ~] = mTRFpredict(stimRight, response, g_right, Fs, 1, or, en, Lcon_R);
    
    disp(['parallel mode, trial ' num2str(j)])
end

% enter the model prediction into the table:
for i = 1:length(S)
    if S(i).a_r_right > S(i).a_r_left
        S(i).prediction = 'right';
    else
        S(i).prediction = 'left';
    end
end

% check if prediction matches the ground truth:
temp = num2cell(strcmp({S.type}, {S.prediction}));
[S.success] = temp{:};

disp(['Model overall accuracy: ' num2str(mean([S.success]))])

r_succ = [S(ismember({S.type}, 'right')).success];
l_succ = [S(ismember({S.type}, 'left')).success];
mu_r_left_corr = mean([S(ismember({S.type}, 'left')).a_r_left]);
mu_r_right_corr = mean([S(ismember({S.type}, 'right')).a_r_right]);
mu_acc_left_corr = mean(l_succ);
mu_acc_right_corr = mean(r_succ);


disp(['Mean correlation on correctly classified right trials '  num2str(mu_r_right_corr)])
disp(['Mean correlation on correctly classified left trials '  num2str(mu_r_left_corr)])
disp(['Mean accuracy on correctly classified right trials '  num2str(mu_acc_right_corr)])
disp(['Mean accuracy on correctly classified left trials '  num2str(mu_acc_left_corr)])
x = [[sum(l_succ),sum(~l_succ)];[sum(r_succ),sum(~r_succ)]];
[~, p, ~] = fishertest(x);
disp(['left/right accurarcy difference (Fisher, p<0.05 = sig. different): ' num2str(p)])

correlations_r_r = [S(ismember({S.type}, 'right')).a_r_right];
correlations_l_l = [S(ismember({S.type}, 'left')).a_r_left];
[~, p] = ttest2(correlations_l_l, correlations_r_r);
disp(['Mean left/right correlations different? (t-test, p<0.05 = sig. different): ' num2str(p)])


