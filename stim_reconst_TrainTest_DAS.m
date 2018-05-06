% Compared to stim_reconst_1_PARFOR.m, this code is about twice as
% efficient.

% load('KOS_1+2_80Hz.mat')

load('/Users/RomanKoshkin/Downloads/EEG_latest/DAS_CH.mat')
clearvars -except EEG
tic

%% define model parameters:
ST =                    'right' % with which channel to correlate
train_test_split =      0.8;    % proportion of train/test samples
train_test_split_RANDOM = 0;    % do we sample train/test sampels randomly?
LAMBDA =                0.47;
len_win_classified =    50;
compute_envelope =      1;
center_normalize =      1;
filtering =             1;
resample =              1;
low_cutoff =            1;
high_cutoff =           30;
DOWNSAMPLE_TO =         64;
% lags start and end:
or = 150;    % kernel origin, ms % ???????????, ??? ??????, ??? ?????
en = 600;

% range of events in the EEG.event struct
events = [1:124]; % event ordinal numbers in the  

ch_left = find(ismember({EEG.chanlocs.labels}, 'Left_AUX') == 1);
ch_right = find(ismember({EEG.chanlocs.labels},'Right_AUX') == 1);
if strcmp(ST, 'right')==1
    ST = ch_right;
else 
    ST = ch_left;
end


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

% initialize an empty struct array to store results:
S = struct('type', [], 'code_no', [], 'latency', [],...
    'a_r', [], 'u_r', []);

Fs = EEG.srate;

% determine what's right, what's left:
for j = events
    if strcmp(EEG.event(j).type, 'L_Lef_on') == 1 
        S(j).type = 'foreign';
        S(j).code_no = j;

    end
    if strcmp(EEG.event(j).type, 'L_Rig_on') == 1
        S(j).type = 'russian';
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


% split our windows into training and testing based on our train/test split
code_nos = [S.code_no];

if train_test_split_RANDOM == 1
    train_events = randsample(code_nos, round(length([S.code_no])*train_test_split));
    test_events = code_nos(~ismember(code_nos, train_events));
else
    train_events = code_nos(1:floor(quantile(1:length(code_nos), train_test_split)));
    test_events = code_nos(find(~ismember(code_nos, train_events)));
end

% test_events = train_events

Lcon = zeros(size(EEG.data, 1)-2, 1); % minus audio channels

% initialize a correctly-sized matrix of nans:
[g,t, ~] = mTRFtrain(rand(1000,1), rand(1000,63), Fs, 1, or, en, LAMBDA);
sz = size(g);
g_att = nan(sz(1), sz(2), length(train_events)); clear sz g t

% FIRST, WE TRAIN DECODERS ON TRAINING TRIALS:
for j = 1:length(train_events) % $$$$$$$$$$$$$$$$$$$$ CHOSE EITHER PARFOR OR FOR.
    addr = train_events(j);
    tic
    start = round(EEG.event(addr).latency);
    fin = round(start + len_win_classified*EEG.srate);

    stim = EEG.data(ST, start:fin)';

    response = EEG.data(1:63, start:fin)';

    [g,t, ~] = mTRFtrain(stim, response, Fs, 1, or, en, LAMBDA);
    
    if strcmp (S(find(ismember([S.code_no], addr))).type, 'russian') == 1
        g_att(:,:,j) = g;
    else
        g_unatt(:,:,j) = g;
    end

    % report progress:
    elapsed_time = toc;
    disp(['Computing decoder from trial:' num2str(j)...
                 ' seconds'...
                ' Kernel length: ' num2str(en) ' Elapsed: '...
                num2str(elapsed_time)])
end

% load onset latencies into S.latency:
temp = num2cell([EEG.event([S.code_no]).latency]);
[S.latency] = temp{:};
    
% average the decoders over all the TRAINING 30-second-long trials:
g_att = nanmean(g_att,3);
g_unatt = nanmean(g_unatt,3);


 
for j = 1:length(test_events) % FOR/PARFOR

    addr = test_events(j);
    start = round(EEG.event(addr).latency);
    fin = round(start + len_win_classified*EEG.srate);

    stim = EEG.data(ST, start:fin)';

    response = EEG.data(1:63, start:fin)';

    s_addr = find(ismember([S.code_no], addr));
    [a_X, S(s_addr).a_r, ~, ~] = mTRFpredict(stim, response, g_att, Fs, 1, or, en, Lcon);
%     [d,Z,tr] = procrustes(stim, a_X);
%     S(s_addr).a_immse = immse(stim,Z);
    
    [u_X, S(s_addr).u_r, ~, ~] = mTRFpredict(stim, response, g_unatt, Fs, 1, or, en, Lcon);
%     [d,Z,tr] = procrustes(stim, u_X);
%     S(s_addr).u_immse = immse(stim,Z);
    
    disp(['parallel mode, trial ' num2str(1:j)])
end

% compute the accuracy of attended decoders:
for j = 1:length(S)
    if strcmp(S(j).type,'russian') == 1
        if S(j).a_r > S(j).u_r
            S(j).r_success = 1;
        else
            S(j).r_success = 0;
        end
    end
    if strcmp(S(j).type,'foreign') == 1
        if S(j).u_r > S(j).a_r
            S(j).r_success = 1;
        else
            S(j).r_success = 0;
        end
    end
end

a_accuracy = sum([S.r_success])/length(test_events);
clc
disp(['Accuracy = ' num2str(a_accuracy)])
disp(['Mean corr on Russian lang. = ' num2str(mean([S.a_r]))])
disp(['Mean corr on foreign lang. = ' num2str(mean([S.u_r]))])