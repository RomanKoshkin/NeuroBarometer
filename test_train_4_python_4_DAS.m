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
% load('/Users/RomanKoshkin/Downloads/EEG_latest/DAS_CH.mat')
% load('/Users/RomanKoshkin/Downloads/EEG_latest/DAS_CH_AVG_500Hz.mat')
filein = 'DAS_CH_AVG_500Hz_2.mat';

load(['/Users/RomanKoshkin/Downloads/EEG_latest/' filein])

disp('dataset loaded')
clearvars -except EEG filein
tic

%% define model parameters:
compute_envelope =      1;
center_normalize =      1;
filtering =             1;
RESAMPLE =              1;
low_cutoff =            1;
high_cutoff =           40;
DOWNSAMPLE_TO =         100;
AUDIO_PREPROC =         1;

TRIAL_LEN = 60; % what's the duration of a trial
WINSIZE = 2; % size of window
STEPSIZE = 2; % step between windows (onset-to-onset)

WAVELET = 0;

% range of events in the EEG.event struct
events = [1:length([EEG.event])]; % event ordinal numbers in the  

CHAN_RANGE =            1:size(EEG.data,1)-2;

ch_left = find(ismember({EEG.chanlocs.labels}, 'Left_AUX') == 1);
ch_right = find(ismember({EEG.chanlocs.labels},'Right_AUX') == 1);

if AUDIO_PREPROC == 1
    Fs = EEG.srate;
    figure; plot (EEG.data(ch_left, 140*Fs:145*Fs)); hold on
    EEG.data(ch_left:ch_right,:) = highpassFIR(EEG.data(ch_left:ch_right,:), Fs, 1, 2, 0);
    plot (EEG.data(ch_left, 140*Fs:145*Fs)); title('Audio before and after highpass filtering');
    
    EEG.data(ch_right,:) = EEG.data(ch_right,:)/std(EEG.data(ch_right,:));
    EEG.data(ch_left,:) = EEG.data(ch_left,:)/std(EEG.data(ch_left,:));
    
    figure; plot (EEG.data(ch_left, 140*Fs:145*Fs)); hold on;
    EEG.data(ch_left:ch_right,:) = bandpassFIR(EEG.data(ch_left:ch_right,:), Fs, 230, 240, 100, 65, 70, 0);
    
    EEG.data(ch_right,:) = EEG.data(ch_right,:)/std(EEG.data(ch_right,:));
    EEG.data(ch_left,:) = EEG.data(ch_left,:)/std(EEG.data(ch_left,:));
    
    plot (EEG.data(ch_left, 140*Fs:145*Fs)); title('z-transformed, bandpass-filtered (~100-150 Hz, F_{0} audio before and after highpass filtering');
    audio = EEG.data(ch_left:ch_right,:);
else
    audio = EEG.data(ch_left:ch_right,:);
end

if center_normalize == 1
    EEG.data = EEG.data-repmat(mean(EEG.data,2),1,size(EEG.data,2));
    EEG.data = EEG.data./std(EEG.data,0, 2);
end
if filtering == 1
    [EEG, ~, ~] = pop_eegfiltnew(EEG, low_cutoff, high_cutoff);
end

Fs = EEG.srate;
if compute_envelope == 1
    % put back the audio:
    EEG.data(ch_left:ch_right,:) = audio;
    
    % diagnostics
    diagn1 = EEG.data(ch_left,:);
    diagn2 = envelope(EEG.data(ch_left,:));
    
    EEG.data(ch_left,:) = envelope(EEG.data(ch_left,:));
    EEG.data(ch_right,:) = envelope(EEG.data(ch_right,:)); 
    
end

if RESAMPLE == 1
    % resample
    EEG = pop_resample(EEG, DOWNSAMPLE_TO);
    diagn3 = EEG.data(ch_left,:);
    Fs = EEG.srate;
end

% diagnostic plots:
figure
subplot (2,1,1)
plot(diagn1(140*500:142*500));
hold on;
len1 = length(diagn1(140*500:142*500));
plot(diagn2(140*500:142*500));
xlim([1 len1])
subplot(2,1,2)
plot(diagn3(140*Fs:142*Fs));
len2 = length(diagn1(140*Fs:142*Fs));
xlim([1 len2])
%%
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

% data split:
counter = 0;
startfin = 0;
for i = 1:length({S.type})
    start = round(S(i).latency);
    fin = start + WINSIZE*Fs-1;
    disp([num2str(start/Fs) '___' num2str((S(i).latency + 30*Fs)/Fs)])
    disp([num2str(fin/Fs) '___' num2str((S(i).latency + 30*Fs)/Fs)])

    while fin < S(i).latency + TRIAL_LEN*Fs
        counter = counter + 1;
        X(counter,:,:) = EEG.data(CHAN_RANGE,start:fin);
        
        startfin(counter,1:2) = [start fin];
        if strcmp(S(i).type, 'russian') == 1
            Z(counter) = 1;
            Q{counter} = 'russian';
            Y(counter,:) = EEG.data(ch_right,start:fin);
        else
            Z(counter) = 0;
            Q{counter} = 'foreign';
            Y(counter,:) = EEG.data(ch_right,start:fin);
        end;
        disp([num2str(counter) '_' S(i).type ' right, trial = ', num2str(i)])
       
        start = start + STEPSIZE*Fs - 1;
        disp([num2str(start/Fs) '___' num2str((S(i).latency + TRIAL_LEN*Fs)/Fs)])
        fin = start + WINSIZE*Fs - 1;    
        disp([num2str(fin/Fs) '___' num2str((S(i).latency + TRIAL_LEN*Fs)/Fs)])
    end
end
Z = Z';
Q = Q';

% if WAVELET == 1
%     
%     window_len = 64; % 100
%     noverlap = 50;
%     nfft = 512;
%     X = zeros(length(startfin), IMSIZE(1), IMSIZE(2), 3);
%     for i = 1:length(startfin)
%           
%         for j = 1:length(CHAN_RANGE)
%             [S,F,T] = spectrogram(EEG.data(CHAN_RANGE(j),startfin(i,1):startfin(i,2)),...
%                 window_len,noverlap,nfft,EEG.srate);
% %             X(i,:,:,j) = abs([S(13:28,:); imresize(S(36:63,:), [15, 32])]).^2;
%             X(i,:,:,j) = imresize((abs(S(42:97,:))).^2, [IMSIZE]);
%         end
%         disp(i)
%     end
% end

if WAVELET==0
    fileout = ['/Users/RomanKoshkin/Downloads/EEG_latest/' ... 
        filein ', ' ...
        'DS2=' num2str(DOWNSAMPLE_TO) 'Hz, '...
        'FIR=' num2str(low_cutoff) '-' ...
        num2str(high_cutoff) 'Hz, ' ...
        'centnorm=', num2str(center_normalize) ', ' ...
        'Env=' num2str(compute_envelope) ', '...
        'TD, ' ...
        num2str(events(1)) '-' num2str(events(end)) '.mat']
    save(fileout, 'X', 'Y', 'Z', 'Q', 'WINSIZE', 'STEPSIZE', 'TRIAL_LEN')
    % DIAGNOSTICS:
    ch_cz = find(ismember({EEG.chanlocs.labels}, 'Cz') == 1);
    ch_x_cz = 2
    figure
    for i = 1:4 % windows:
        trial = i;
        subplot(4,1,i)
        plot(startfin(i,1):startfin(i,2),...
            EEG.data(ch_cz, startfin(trial,1):startfin(trial,2)));hold on
        plot(startfin(i,1):startfin(i,2),...
            squeeze(X(trial,ch_x_cz,:)))
        title(trial)
        ylim([-20 10])
    end
end

% if WAVELET==1
%     figure
%     for i = 1:size(X,4)
%         subplot(1,size(X,4),i)
%         imagesc(squeeze(X(465,:,:,i)))
%     end
%     
%     fileout = ['/Users/RomanKoshkin/Downloads/' filein '->' num2str(low_cutoff) '-' num2str(high_cutoff) 'Hz,' 'Env=' num2str(COMPUTE_ENVELOPE) '_FD' '.mat']
%     save(fileout, 'X', 'Y', 'Z', 'WINSIZE', 'STEPSIZE', 'TRIAL_LEN')
% end

