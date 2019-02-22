%% OR WORK WITH ICA-CLEANED DATA (AUDIO ALREADY PREPROCESSED, ENVELOPE COMPUTED)
clearvars -except EEG
% load('/Volumes/Transcend/NeuroBarometer/EEG_latest/EEG_ICA(-123_ICs)+proc_AUD_101_192_Merged456.mat')
% load('/Volumes/Transcend/NeuroBarometer/EEG_latest/Merged456-1-94_ICA(-2,3ICs)+AUDpreproc.mat')
% load('/Volumes/Transcend/NeuroBarometer/EEG_latest/Merged456-197-289_ICA(-eyes)+AUDpreproc.mat')
load('/Volumes/Transcend/NeuroBarometer/EEG_latest/Merged456-197-289_ICA(ANDeyes)+AUDpreproc.mat')
% load('/Volumes/Transcend/NeuroBarometer/EEG_latest/Merged123-143-202_ICA(-Eyes)+AUDpreproc.mat')

% load('/Volumes/Transcend/NeuroBarometer/EEG_latest/Merged123-143-202_ICA(+Eyes)+AUDpreproc.mat')

% load('/Volumes/Transcend/NeuroBarometer/EEG_latest/Merged123_75_134_ICA(-eyes)AUDpreproc.mat')
% load('/Volumes/Transcend/NeuroBarometer/EEG_latest/Merged123_75_134_ICA(+eyes)AUDpreproc.mat')
% load('/Volumes/Transcend/NeuroBarometer/EEG_latest/Merged123_1_64_ICA(+eyes)AUDpreproc.mat')

% filein = 'Merged456-1-94_ICA(-2,3ICs)+AUDpreproc.mat';
filein = 'EEG_ICA(-123_ICs)+proc_AUD_101_192_Merged456.mat';
% filein = 'Merged456-197-289_ICA(-eyes)+AUDpreproc.mat';
% filein = 'Merged456-197-289_ICA(ANDeyes)+AUDpreproc.mat';

% filein = 'Merged123_1_64_ICA(-eyes)AUDpreproc.mat';
% filein = 'Merged123_75_134_ICA(-eyes)AUDpreproc.mat';
% filein = 'Merged123-143-202_ICA(-Eyes)+AUDpreproc.mat';


load(['/Volumes/Transcend/NeuroBarometer/EEG_latest/' filein])
 

%% define model parameters:
TRIAL_LEN = 30; % what's the duration of a trial
WINSIZE = 2; % size of window
STEPSIZE = 2; % step between windows (onset-to-onset)

WAVELET = 0;
IMSIZE = [28 28];
compute_envelope =      1;
center_normalize =      1;
filtering =             1;
RESAMPLE =              1;
low_cutoff =                2; %1
high_cutoff =               30; %9
AudioLoCutoff =         5;
AudioHiCutoff =         900;
DOWNSAMPLE_TO =         64;    % 64
AUDIO_PREPROC =         0;

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

%% data split:
counter = 0;
startfin = 0;
for i = 1:length({S.type})
    start = round(S(i).latency);
    fin = start + WINSIZE*Fs-1;
    disp([num2str(start/Fs) '___' num2str((S(i).latency + TRIAL_LEN*Fs)/Fs)])
    disp([num2str(fin/Fs) '___' num2str((S(i).latency + TRIAL_LEN*Fs)/Fs)])

    while fin < S(i).latency + TRIAL_LEN*Fs
        counter = counter + 1;
        X(counter,:,:) = EEG.data(CHAN_RANGE,start:fin);
        
        startfin(counter,1:2) = [start fin];
        if strcmp(S(i).type, 'right') == 1
            disp([num2str(counter) '_' S(i).type ' right, trial = ', num2str(i)])
            Z(counter) = 1;
            Q{counter} = 'right';
            Y(counter,:) = EEG.data(ch_right,start:fin);
            L(counter,:) = EEG.data(ch_left,start:fin);
            R(counter,:) = EEG.data(ch_right,start:fin);
        else
            disp([num2str(counter) '_' S(i).type ' left, trial = ', num2str(i)])
            Z(counter) = 0;
            Q{counter} = 'left';
            Y(counter,:) = EEG.data(ch_left,start:fin);
            L(counter,:) = EEG.data(ch_left,start:fin);
            R(counter,:) = EEG.data(ch_right,start:fin);
        end
        
       
        start = start + STEPSIZE*Fs - 1;
        disp([num2str(start/Fs) '___' num2str((S(i).latency + TRIAL_LEN*Fs)/Fs)])
        fin = start + WINSIZE*Fs - 1;    
        disp([num2str(fin/Fs) '___' num2str((S(i).latency + TRIAL_LEN*Fs)/Fs)])
    end
end
Z = Z';
Q = Q';

if WAVELET == 1
    
    window_len = 64; % 100
    noverlap = 50;
    nfft = 512;
    X = zeros(length(startfin), IMSIZE(1), IMSIZE(2), 3);
    for i = 1:length(startfin)
          
        for j = 1:length(CHAN_RANGE)
            [SI,F,T] = spectrogram(EEG.data(CHAN_RANGE(j),startfin(i,1):startfin(i,2)),...
                window_len,noverlap,nfft,EEG.srate);
%             X(i,:,:,j) = abs([SI(13:28,:); imresize(SI(36:63,:), [15, 32])]).^2;
            X(i,:,:,j) = imresize((abs(SI(42:97,:))).^2, [IMSIZE]);
        end
        disp(i)
    end
end

if WAVELET == 2
%     FF = [5:8:65];
    [f_, FFT_] = get_fft(1, startfin(1,1), startfin(1,2));
    X = zeros(length(startfin), 67, 67, length(f_));
    chan_by_fft = zeros(length(CHAN_RANGE),length(f_));
    
    for Trial = 1:length(startfin)
       disp(['processing trial '  num2str(Trial)])
        for Chan = 1:length(CHAN_RANGE)
            [~, chan_by_fft(Chan,:)] =  get_fft(Chan, startfin(Trial,1), startfin(Trial,2));
        end
        freq_counter = 0;
        for Freq = 1:size(chan_by_fft,2) %  [5:8:65] % 
%             freq_counter = freq_counter + 1;
            [~,X(Trial,:,:,Freq),~] = topoplot_lite(chan_by_fft(:,Freq), EEG.chanlocs(CHAN_RANGE), 'verbose', 'off', 'noplot', 'on');
%             X(Trial,:,:,Freq) = randn(67,67);
        end
%         for j = 1:5
%             subplot(1,5,j)
%             [~,val(:,:,j),~] = topoplot(chan_by_fft(:,j), EEG.chanlocs(CHAN_RANGE), 'noplot', 'on');
%             imagesc(squeeze(val(:,:,j)))
%         end
%         for j = 1:5
%             subplot(2,5,j)
%             imagesc(squeeze(X(1,:,:,j+j)))
%             title(['Freq' num2str(j+j)])
%             subplot(2,5,j+5)
%             imagesc(squeeze(X(2,:,:,j+j)))
%             title(['Freq' num2str(j+j)])
%         end
    end
        fileout = ['/Volumes/Transcend/NeuroBarometer/EEG_latest/' ... 
        filein ', ' ...
        'DS2=' num2str(DOWNSAMPLE_TO) 'Hz, '...
        'FIR=' num2str(low_cutoff) '-' ...
        num2str(high_cutoff) 'Hz, ' ...
        'centnorm=', num2str(center_normalize) ', ' ...
        'step=' num2str(STEPSIZE) ', '...
        'win=' num2str(WINSIZE) ', '...
        'TOPO, '...
        '.mat']
    X(isnan(X))=0;
    save(fileout, 'X', 'Y', 'Z', 'Q', 'WINSIZE', 'STEPSIZE', 'TRIAL_LEN')
end

if WAVELET == 0
    fileout = ['/Volumes/Transcend/NeuroBarometer/EEG_latest/' ... 
        filein ', ' ...
        'DS2=' num2str(DOWNSAMPLE_TO) 'Hz, '...
        'FIR=' num2str(low_cutoff) '-' ...
        num2str(high_cutoff) 'Hz, ' ...
        'centnorm=', num2str(center_normalize) ', ' ...
        'step=' num2str(STEPSIZE) ', '...
        'win=' num2str(WINSIZE) ', '...
        'TD, ' ...
        num2str(events(1)) '-' num2str(events(end)) '.mat']
    save(fileout, 'X', 'Y', 'Z', 'Q', 'R', 'L', 'WINSIZE', 'STEPSIZE', 'TRIAL_LEN')
    % DIAGNOSTICS:
    ch_cz = find(ismember({EEG.chanlocs.labels}, 'Cz') == 1);
    figure
    for i = 1:4 % windows:
        trial = i;
        subplot(4,1,i)
        plot(startfin(i,1):startfin(i,2),...
            EEG.data(ch_cz, startfin(trial,1):startfin(trial,2)));hold on
        plot(startfin(i,1):startfin(i,2),...
            squeeze(X(trial,ch_cz,:)))
        title([num2str(trial) ' Cz'])
        ylim([-3 3])
    end
end
%%
subplot(1,3,1)
imagesc(squeeze(mean(X(1,:,:,4:7), 4)))
title('Theta')

subplot(1,3,2)
imagesc(squeeze(mean(X(1,:,:,8:12), 4)))
title('Alpha')

subplot(1,3,3)
imagesc(squeeze(mean(X(1,:,:,13:30), 4)))
title('Beta')