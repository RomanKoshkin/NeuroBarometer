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

load('/Volumes/Transcend/NeuroBarometer/EEG_latest/Merged123_75_134_ICA(-eyes)AUDpreproc.mat')
% load('/Volumes/Transcend/NeuroBarometer/EEG_latest/Merged123_75_134_ICA(+eyes)AUDpreproc.mat')
% load('/Volumes/Transcend/NeuroBarometer/EEG_latest/Merged123_1_64_ICA(+eyes)AUDpreproc.mat')
% load('/Volumes/Transcend/NeuroBarometer/EEG_latest/Merged123_1_64_ICA(-eyes)AUDpreproc.mat')
  

%% define model parameters:
train_test_split_RANDOM = 0;
train_test_split =      0.8;
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
end

% test_events = train_events
% test_events = code_nos;

% if you wanna get a return from the a parfor loop, you need to declare the
% variables, with the RIGHT SIZES!!!. Parfor works like a function. It only
% returns what has been declared before. If you define a var inside a
% parfor loop, it is never returned.
% Initialize vars for the parfor loop:
Lcon = zeros(size(EEG.data, 1)-2, 1); % minus audio channels

g_left = [];
g_right = [];

% FIRST, WE TRAIN DECODERS (FOR UNSHIFTED STIM/RESP) ON TRAINING TRIALS:
for j = 1:length(train_events) % $$$$$$$$$$$$$$$$$$$$ CHOSE EITHER PARFOR OR FOR.
    addr = train_events(j);
    tic
    start = round(EEG.event(addr).latency);
    fin = round(start + len_win_classified*EEG.srate);

    stimLeft = EEG.data(ch_left, start:fin)';
    stimRight = EEG.data(ch_right, start:fin)';
    
    response = EEG.data(CHAN_RANGE, start:fin)';

    [wLeft,t, ~] = mTRFtrain(stimLeft, response, Fs, 1, or, en, LAMBDA);
    [wRight,t, ~] = mTRFtrain(stimRight, response, Fs, 1, or, en, LAMBDA);
    
    g_right = cat(3, g_right, wRight);
    g_left = cat(3, g_left, wLeft);
    
    % report progress:
    elapsed_time = toc;
    disp(['Computing decoder from trial:' num2str(j)...
                 ' seconds'...
                ' Kernel length: ' num2str(en) ' Elapsed: '...
                num2str(elapsed_time)])
end
    
% average the decoders over all the TRAINING 30-second-long trials:
g_right = mean(g_right,3);
g_left = mean(g_left,3);

for j = 1:length(test_events) % FOR/PARFOR

    addr = test_events(j);
    start = round(EEG.event(addr).latency);
    fin = round(start + len_win_classified*EEG.srate);

    stimLeft = EEG.data(ch_left, start:fin)';
    stimRight = EEG.data(ch_right, start:fin)';

    response = EEG.data(CHAN_RANGE, start:fin)';

    s_addr = find(ismember([S.code_no], addr));
    [~, S(s_addr).LchLdec, ~, ~] = mTRFpredict(stimLeft, response, g_left, Fs, 1, or, en, Lcon);
    [~, S(s_addr).RchRdec, ~, ~] = mTRFpredict(stimRight, response, g_right, Fs, 1, or, en, Lcon);

    disp(['parallel mode, trial ' num2str(j)])
end

% compute the accuracy of attended decoders:
for j = find(ismember([S.code_no], test_events));
    if strcmp(S(j).type,'right') == 1
        if S(j).RchRdec > S(j).LchLdec
            S(j).r_success = 1;
        else
            S(j).r_success = 0;
        end
    end
    if strcmp(S(j).type,'left') == 1
        if S(j).LchLdec > S(j).RchRdec
            S(j).r_success = 1;
        else
            S(j).r_success = 0;
        end
    end
end

R_nos = find(ismember({S.type}, 'right'));
L_nos = find(ismember({S.type}, 'left'));

a_accuracy = sum([S(find(ismember([S.code_no], test_events))).r_success])/length(test_events);
clc
disp(['Accuracy = ' num2str(a_accuracy)])