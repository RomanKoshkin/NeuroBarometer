%% PRE-PROCESSING PROTOCOL 1: \n
% =========================\n
% - import raw DAS197-289\n
% - notch 49-51 Hz on all but audio(eeglab)\n
% - bandpass 1-60 on all but audio (eeglab)\n
% - compute envelope (on AUX_left and AUX_right)\n
% - resample to 250 Hz\n
% - Re-reference to average (excluding audio channels)\n
% - Edit channel locations\n
% - Binica on all but audio (eeglab)\n
%%
clc
disp('loading dataset...')
% load('/Volumes/Transcend/NeuroBarometer/EEG_latest/DAS_CH.mat')
load('/Volumes/Transcend/NeuroBarometer/EEG_latest/DAS_CH_AVG_500Hz.mat')
% load('/Volumes/Transcend/NeuroBarometer/EEG_latest/DAS_CH_AVG_500Hz_2.mat')
% load('/Volumes/Transcend/NeuroBarometer/EEG_latest/DAS_raw.mat')

disp('dataset loaded')
clearvars -except EEG
tic

%% define model parameters:
ST =                    'left' % with which channel to correlate
train_test_split_RANDOM = 0;
train_test_split =      0.7;
LAMBDA =                0.47;
len_win_classified =    60;
compute_envelope =      1;
center_normalize =      1;
filtering =             1;
RESAMPLE =              1;
low_cutoff =            1;
high_cutoff =           9;
AudioLoCutoff =         2;
AudioHiCutoff =         240;
DOWNSAMPLE_TO =         64;
AUDIO_PREPROC =         1;
% lags start and end:
or = 100;    % kernel origin, ms % ???????????, ??? ??????, ??? ?????
en = 300;

% range of events in the EEG.event struct
events = [1:length([EEG.event])]; % event ordinal numbers in the  

CHAN_RANGE =            1:size(EEG.data,1)-2;

ch_left = find(ismember({EEG.chanlocs.labels}, 'Left_AUX') == 1);
ch_right = find(ismember({EEG.chanlocs.labels},'Right_AUX') == 1);
if strcmp(ST, 'right')==1
    ST = ch_right;
else 
    ST = ch_left;
end

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
%%
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

    response = EEG.data(CHAN_RANGE, start:fin)';

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

    response = EEG.data(CHAN_RANGE, start:fin)';

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

%%
tab_no = 4;

addr = S(tab_no).code_no;
start = round(EEG.event(addr).latency);
fin = round(start + len_win_classified*EEG.srate);

stim = EEG.data(ST, start:fin)';

response = EEG.data(CHAN_RANGE, start:fin)';
[stim_hat, ~, ~, ~] = mTRFpredict(stim, response, g_att, Fs, 1, or, en, Lcon);
figure
plot(stim)
hold on
plot(stim_hat)
title(['Correlation on ' S(addr).type ' is ' num2str(corr(stim, stim_hat))])
