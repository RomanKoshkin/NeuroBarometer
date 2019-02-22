% %% load raw data (if necessary).
% 
% % range of events in the EEG.event struct
% % events = [5:64, 75:134, 143:202];     % Merged123
% % events = [1:94], [101:192], [197:289] % Merged456
% 
% evs = [197 289];
% clc
% disp('loading dataset...')
% load('/Volumes/Transcend/NeuroBarometer/Merged456.mat')
% % load('/Volumes/Transcend/NeuroBarometer/Merged123.mat')
% disp('dataset loaded')
% 
% start = EEG.event(evs(1)).latency/EEG.srate;
% fin = EEG.event(evs(2)).latency/EEG.srate;
% EEG = pop_select(EEG, 'time', [start fin]);
% disp('EEG time-based selection complete')
% clearvars -except EEG
% tic

%% OR WORK WITH ICA-CLEANED DATA (AUDIO ALREADY PREPROCESSED, ENVELOPE COMPUTED)
clearvars -except EEG
% load('/Volumes/Transcend/NeuroBarometer/EEG_latest/EEG_ICA(-123_ICs)+proc_AUD_101_192_Merged456.mat')
% load('/Volumes/Transcend/NeuroBarometer/EEG_latest/Merged456-1-94_ICA(-2,3ICs)+AUDpreproc.mat')
% load('/Volumes/Transcend/NeuroBarometer/EEG_latest/Merged456-197-289_ICA(-eyes)+AUDpreproc.mat')
% load('/Volumes/Transcend/NeuroBarometer/EEG_latest/Merged456-197-289_ICA(ANDeyes)+AUDpreproc.mat')
% load('/Volumes/Transcend/NeuroBarometer/EEG_latest/Merged123-143-202_ICA(-Eyes)+AUDpreproc.mat')

% load('/Volumes/Transcend/NeuroBarometer/EEG_latest/Merged123-143-202_ICA(+Eyes)+AUDpreproc.mat')

% load('/Volumes/Transcend/NeuroBarometer/EEG_latest/Merged123_75_134_ICA(-eyes)AUDpreproc.mat')
% load('/Volumes/Transcend/NeuroBarometer/EEG_latest/Merged123_75_134_ICA(+eyes)AUDpreproc.mat')
% load('/Volumes/Transcend/NeuroBarometer/EEG_latest/Merged123_1_64_ICA(+eyes)AUDpreproc.mat')
load('/Volumes/Transcend/NeuroBarometer/EEG_latest/Merged123_1_64_ICA(-eyes)AUDpreproc.mat')
  

%% define model parameters:
train_test_split_RANDOM = 0;
train_test_split =      0.3;
LAMBDA =                0.07;
len_win_classified =    30;
compute_envelope =      1;
center_normalize =      1;
filtering =             1;
RESAMPLE =              1;
low_cutoff =            1;
high_cutoff =           9;
AudioLoCutoff =         5;
AudioHiCutoff =         900;
DOWNSAMPLE_TO =         64;
AUDIO_PREPROC =         0;
% lags start and end:
or = 0;    % kernel origin, ms % ???????????, ??? ??????, ??? ?????
en = 300;

% range of events in the EEG.event struct
events = [1:length([EEG.event])]; % event ordinal numbers in the  

CHAN_RANGE =            1:size(EEG.data,1)-2;

ch_left = find(ismember({EEG.chanlocs.labels}, 'Left_AUX') == 1);
ch_right = find(ismember({EEG.chanlocs.labels},'Right_AUX') == 1);


if AUDIO_PREPROC == 1
    Fs = EEG.srate;
    
    AUDIO = pop_select(EEG, 'channel', [ch_left:ch_right]);
    AUDIO = pop_eegfiltnew(AUDIO, AudioLoCutoff, AudioHiCutoff);
    
    AUDIO.data(1,:) = AUDIO.data(1,:)./std(AUDIO.data(1,:));
    AUDIO.data(2,:) = AUDIO.data(2,:)./std(AUDIO.data(2,:));
    
    plot(AUDIO.data(2,140*Fs:145*Fs)); hold on;
    
    AUDIO.data(1,:) = envelope(AUDIO.data(1,:));
    AUDIO.data(2,:) = envelope(AUDIO.data(2,:));
    
    plot(AUDIO.data(2,140*Fs:145*Fs)); hold on;
    title('Original and Envelope')
else
    AUDIO = pop_select(EEG, 'channel', [ch_left:ch_right]);
end

if center_normalize == 1
    for i = 1:size(EEG.data,1)
    EEG.data(i,:) = EEG.data(i,:) - mean(EEG.data(i,:));
    EEG.data(i,:) = EEG.data(i,:)./std(EEG.data(i,:));
    disp(['centering & z-transforming channel ' num2str(i)])
    end
    clc
end

if RESAMPLE == 1
    disp(['resampling EEG to ' num2str(DOWNSAMPLE_TO) ' Hz'])
    EEG = pop_resample(EEG, DOWNSAMPLE_TO);
    disp(['resampling AUDIO to ' num2str(DOWNSAMPLE_TO) ' Hz'])
    AUDIO = pop_resample(AUDIO, DOWNSAMPLE_TO);
    Fs = EEG.srate;
end

if filtering == 1
    disp(['filtering EEG between' num2str(low_cutoff) ' and ' num2str(high_cutoff)])
    [EEG, ~, ~] = pop_eegfiltnew(EEG, low_cutoff, high_cutoff);
    % put back the UNFILTERED, but downsampled, envelope:
    disp('putting the audio back...')
    EEG.data(ch_left:ch_right,:) = AUDIO.data(1:2,:);
end
clear AUDIO
pop_eegplot(EEG, 1, 0, 1);
disp('Preprocessing complete in...')
toc

% initialize an empty struct array to store results:
S = struct('type', [], 'code_no', [], 'latency', [],...
    'a_r', [], 'u_r', []);

Fs = EEG.srate;
%%
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

    if strcmp(EEG.event(j).type, 'other') == 1 ||...
       strcmp(EEG.event(j).type, 'L_Lef_off') == 1 ||...
       strcmp(EEG.event(j).type, 'L_Rig_off') == 1
        continue
    end
end

% get rid of empty rows:
S = S(~cellfun('isempty',{S.code_no}));

% load onset latencies into S.latency:
temp = num2cell([EEG.event([S.code_no]).latency]);
[S.latency] = temp{:};

% split our windows into training and testing based on our train/test split
code_nos = [S.code_no];

if train_test_split_RANDOM == 1
    train_events = randsample(code_nos, round(length([S.code_no])*train_test_split));
    test_events = code_nos(~ismember(code_nos, train_events));
else
    train_events = code_nos(1:floor(quantile(1:length(code_nos), train_test_split)));
    test_events = code_nos(find(~ismember(code_nos, train_events)));
    test_trials = find(~ismember(code_nos, train_events));
end

% test_events = train_events
% test_events = code_nos;

% if you wanna get a return from the a parfor loop, you need to declare the
% variables, with the RIGHT SIZES!!!. Parfor works like a function. It only
% returns what has been declared before. If you define a var inside a
% parfor loop, it is never returned.
% Initialize vars for the parfor loop:
Lcon = zeros(size(EEG.data, 1)-2, 1); % minus audio channels

%%
g_att = [];
g_unatt = [];
code_nos = [S.code_no];

% FIRST, WE TRAIN DECODERS on ALL The trials:
for j = 1:length(S)
    
    addr = code_nos(j);
    
    start = round(EEG.event(addr).latency);
    fin = round(start + len_win_classified*EEG.srate);
    
    if strcmp(S(j).type,'right')==1
        AttendedStim = EEG.data(ch_right, start:fin)';
        UnAttendedStim = EEG.data(ch_left, start:fin)';
    else
        AttendedStim = EEG.data(ch_left, start:fin)';
        UnAttendedStim = EEG.data(ch_right, start:fin)';
    end

    response = EEG.data(CHAN_RANGE, start:fin)';

    [G_att, t, ~] = mTRFtrain(AttendedStim, response, Fs, 1, or, en, LAMBDA);
    [G_unatt, t, ~] = mTRFtrain(UnAttendedStim, response, Fs, 1, or, en, LAMBDA);
    
    g_att = cat(3, g_att, G_att);
    g_unatt = cat(3, g_unatt, G_unatt);
    
    % report progress:
    disp(['Computing decoder from trial:' num2str(j)...
                 ' seconds'...
                ' Kernel length: ' num2str(en)])
end

R_nos = find(ismember({S.type}, 'right'));
L_nos = find(ismember({S.type}, 'left'));

%% CROSS-VALIDATE:
for j = test_trials % FOR/PARFOR

    start = round(EEG.event(code_nos(j)).latency);
    fin = round(start + len_win_classified*EEG.srate);

    stimRight = EEG.data(ch_right, start:fin)';
    stimLeft = EEG.data(ch_left, start:fin)';
    
    response = EEG.data(CHAN_RANGE, start:fin)';
    
    g_att_tmp = g_att;
    g_unatt_tmp = g_unatt;
    g_att_tmp(:,:,test_trials) = NaN;
    g_unatt_tmp(:,:,test_trials) = NaN;
        
    g_att_tmp = nanmean(g_att_tmp,3);
    g_unatt_tmp = nanmean(g_unatt_tmp,3);
    
    [a_X, S(j).Rch_Adec, ~, ~] = mTRFpredict(stimRight, response, g_att_tmp, Fs, 1, or, en, Lcon);
    [a_X, S(j).Lch_Adec, ~, ~] = mTRFpredict(stimLeft, response, g_att_tmp, Fs, 1, or, en, Lcon);
    [a_X, S(j).Rch_Udec, ~, ~] = mTRFpredict(stimRight, response, g_unatt_tmp, Fs, 1, or, en, Lcon);
    [a_X, S(j).Lch_Udec, ~, ~] = mTRFpredict(stimLeft, response, g_unatt_tmp, Fs, 1, or, en, Lcon);
 
    disp(['parallel mode, trial ' num2str(j)])
end

% compute the accuracy of attended decoders:
for j = test_trials
    if strcmp(S(j).type,'right') == 1
        if S(j).Rch_Adec > S(j).Lch_Adec
            S(j).A_success = 1;
        else
            S(j).A_success = 0;
        end
    end
    if strcmp(S(j).type,'left') == 1
        if S(j).Lch_Adec > S(j).Rch_Adec
            S(j).A_success = 1;
        else
            S(j).A_success = 0;
        end
    end
end

for j = test_trials
    if strcmp(S(j).type,'right') == 1
        if S(j).Rch_Udec > S(j).Lch_Udec
            S(j).U_success = 1;
        else
            S(j).U_success = 0;
        end
    end
    if strcmp(S(j).type,'left') == 1
        if S(j).Lch_Udec > S(j).Rch_Udec
            S(j).U_success = 1;
        else
            S(j).U_success = 0;
        end
    end
end

a_accuracy = sum([S.A_success])/length(test_trials);
u_accuracy = sum([S.U_success])/length(test_trials);
clc
disp(['Overall Accuracy (Attended Decoders) = ' num2str(a_accuracy)])
disp(['Accuracy (att_dec) on right trials = ' num2str(mean([S(R_nos).A_success]))])
disp(['Accuracy (att_dec) on left trials = ' num2str(mean([S(L_nos).A_success]))])

disp(['Overall Accuracy (Unattended Decoders) = ' num2str(u_accuracy)])
disp(['Accuracy (unatt_dec) on right trials = ' num2str(mean([S(R_nos).U_success]))])
disp(['Accuracy (unatt_dec) on left trials = ' num2str(mean([S(L_nos).U_success]))])