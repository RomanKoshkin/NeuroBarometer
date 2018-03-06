% Compared to stim_reconst_1_PARFOR.m, this code is about twice as
% efficient.

% load('KOS_1+2_80Hz.mat')

load('KOS_DAS_80Hz.mat')
clearvars -except EEG
tic
%% define model parameters:
LAMBDA = 0.02;
len_win_classified = 30;
shift_sec = [0];

compute_envelope = 1;
% lags start and end:
or = 0;    % kernel origin, ms % ???????????, ??? ??????, ??? ?????
en = 500;

% range of events in the EEG.event struct
% events = [5:64, 75:134, 143:202]; % event ordinal numbers in the  
events = [5:64]; % event ordinal numbers in the  

% initialize an empty struct array with ALL the necessary fields.
% Otherwise the PARFOR loops won't run.
S = struct('type', [], 'code_no', [], 'latency', [],...
    'a_r_left', [], 'u_r_left', [], 'a_r_right', [], 'u_r_right', []);


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
Lcon = ones(size(EEG.data, 1)-2, 1); % minus audio channels

% load onset latencies into S.latency:
temp = num2cell([EEG.event([S.code_no]).latency]);
[S.latency] = temp{:};

%% now split the data into two large continuous subsets (attend right, attend left)
att_right = [S(find(ismember({S.type}, 'right'))).code_no];
att_left = [S(find(ismember({S.type}, 'left'))).code_no];

stimLeft_A = [];
stimRight_A = [];
stimLeft_U = [];
stimRight_U = [];

respRight_A = [];
respLeft_U = [];
respLeft_A = [];
respRight_U = [];

for i = 1:length(S)
    start = round(EEG.event(i).latency);
    fin = start + 30*EEG.srate-1;
    
    if strcmp(S(i).type, 'right')==1
        stimRight_A = cat(2, stimRight_A, EEG.data(ch_right, start:fin));
        respRight_A = cat(2, respRight_A, EEG.data(1:60, start:fin));
        stimLeft_U = cat(2, stimLeft_U, EEG.data(ch_left, start:fin));
        respLeft_U = cat(2, respLeft_U, EEG.data(1:60, start:fin));
    else
        stimLeft_A = cat(2, stimLeft_A, EEG.data(ch_left, start:fin));
        respLeft_A = cat(2, respLeft_A, EEG.data(1:60, start:fin));
        stimRight_U = cat(2, stimRight_U, EEG.data(ch_right, start:fin));
        respRight_U = cat(2, respRight_U, EEG.data(1:60, start:fin));
    end
end

stimLeft_A = stimLeft_A';
stimRight_A = stimRight_A';
stimLeft_U = stimLeft_U';
stimRight_U = stimRight_U';

respRight_A = respRight_A';
respLeft_U = respLeft_U';
respLeft_A = respLeft_A';
respRight_U = respRight_U';

% and find the decoders on these large CONCATENATED subsets:
[a_r_right,t, ~] = mTRFtrain(   stimRight_A,   respRight_A, Fs, 1, or, en, LAMBDA);
[a_r_left,t, ~] = mTRFtrain(    stimLeft_A,    respLeft_A, Fs, 1, or, en, LAMBDA);
[u_r_right,t, ~] = mTRFtrain(   stimRight_U,   respRight_U, Fs, 1, or, en, LAMBDA);
[u_r_left,t, ~] = mTRFtrain(    stimLeft_U,    respLeft_U, Fs, 1, or, en, LAMBDA);

    
parfor j = 1:length(S) % FOR/PARFOR

    start = round(S(j).latency);
    fin = round(start + len_win_classified*EEG.srate);

    if compute_envelope == 1
        stimLeft = abs(hilbert(EEG.data(ch_left, start:fin)))';
        stimRight = abs(hilbert(EEG.data(ch_right, start:fin)))';
    else
        stimLeft = EEG.data(ch_left, start:fin)';
        stimRight = EEG.data(ch_right, start:fin)';
    end

    response = EEG.data(1:60, start:fin)';
   
    
    [~, S(j).a_r_left, ~, ~] = mTRFpredict(stimLeft, response, a_r_left, Fs, 1, or, en, Lcon);
    [~, S(j).a_r_right, ~, ~] = mTRFpredict(stimRight, response, a_r_right, Fs, 1, or, en, Lcon);

    [~, S(j).u_r_left, ~, ~] = mTRFpredict(stimLeft, response, u_r_left, Fs, 1, or, en, Lcon);
    [~, S(j).u_r_right, ~, ~] = mTRFpredict(stimRight, response, u_r_right, Fs, 1, or, en, Lcon);
    
    disp(['parallel mode, trial ' num2str(j)])
end

% enter the model prediction into the table:
for i = 1:length(S)
    if S(i).u_r_left > S(i).a_r_left
        S(i).prediction = 'right';
    else
        S(i).prediction = 'left';
    end
end

% check if prediction matches the ground truth:
temp = num2cell(strcmp({S.type}, {S.prediction}));
[S.success] = temp{:};
disp(['Model accuracy: ' num2str(mean([S.success]))])
disp(['Mean a_r_right: ' num2str(mean([S.a_r_right]))])
disp(['Mean u_r_right: ' num2str(mean([S.u_r_right]))])

