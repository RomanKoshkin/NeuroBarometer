clear

filein = 'Merged123_250Hz';
% filein = 'Merged123';
% filein = 'Merged456';
% filein = 'KOS_100Hz_ICA';
load(['/Volumes/Transcend/NeuroBarometer/' filein '.mat'])

CHAN_RANGE = 1:60;

WAVELET = 0;
IMSIZE = [40, 32];
COMPUTE_ENVELOPE = 1;
DOWNSAMPLING = 1;
DOWNSAMPLE_TO = 80;
CENTER_NORMALIZE = 1;
% FILTER_AUDIO = 0;
% FILTER_EEG = 0;
%     stopband = 8.5;
%     passband = 8;
%     order = 1000;
FILTER_ALL = 1;
    low_cutoff = 1;
    high_cutoff = 38;
TRIAL_LEN = 30; % what's the duration of a trial
WINSIZE = 2; % size of window
STEPSIZE = 2; % step between windows (onset-to-onset)

% range of events in the EEG.event struct
% events = [5:64, 75:134, 143:202];     % Merged123
% events = [1:94], [101:192], [197:289] % Merged456

events = [143:202];

% for Merged456.mat
% events = [1:94]; % [101:192], [101:192], [197:289] 

% initialize an empty struct array to store results:
S = struct('type', [], 'code_no', [], 'latency', [],...
    'a_r_right', [], 'u_r_left', [],...
    'a_r_left', [], 'u_r_right', []);
ch_left = find(ismember({EEG.chanlocs.labels}, 'Left_AUX') == 1);
ch_right = find(ismember({EEG.chanlocs.labels},'Right_AUX') == 1);
Fs = EEG.srate;

% if FILTER_AUDIO == 1
%     [l, r] = filt_audio(EEG.data(ch_left,:), EEG.data(ch_right,:), Fs, stopband, passband, order);
%     figure; plot(EEG.data(61,1000:1300));hold on;plot(l(1000:1300))
%     EEG.data(ch_left,:) = l;
%     EEG.data(ch_right,:) = r;  
% end
% if FILTER_EEG == 1
%     EEG.data(CHAN_RANGE, :) = ...
%         filt_EEG(EEG.data(CHAN_RANGE,:), Fs, stopband, passband, order);
% end

if CENTER_NORMALIZE==1
    EEG.data = EEG.data-repmat(mean(EEG.data,2),1,size(EEG.data,2));
    STD = std(EEG.data,0, 2);
    for i = 1:size(EEG.data,1)
        EEG.data(i,:) = EEG.data(i,:)/STD(i,:);
    end
end

if FILTER_ALL == 1
    [EEG, ~, ~] = pop_eegfiltnew(EEG, low_cutoff, high_cutoff);
end

if COMPUTE_ENVELOPE == 1
    figure; plot(EEG.data(61,1000:1300), 'LineWidth', 1); hold on
%     EEG.data(ch_left,:) = abs(hilbert(EEG.data(ch_left,:)));
%     EEG.data(ch_right,:) = abs(hilbert(EEG.data(ch_right,:)));
    EEG.data(ch_left,:) = envelope(EEG.data(ch_left,:));
    EEG.data(ch_right,:) = envelope(EEG.data(ch_right,:));
    plot(EEG.data(61,1000:1300), 'LineWidth', 3)
end


if DOWNSAMPLING == 1
    disp(['DOWNSAMPLING to ' num2str(DOWNSAMPLE_TO) ' Hz....'])
    show_chan = 13;
    
    % if you use this matlab's built-in function you'll do fine except that
    % it would mess up the latencies. So don't use it. Use pop_resample:
    % res = resample(double(EEG.data)', DOWNSAMPLE_TO, Fs)';
    EEG1 = pop_resample(EEG, DOWNSAMPLE_TO);
    figure
    subplot (2,1,1)
    plot(EEG.data(show_chan,300*Fs:302*Fs))
    xlim([1 Fs*2])
    title('Before downsampling'); grid on
    subplot(2,1,2)
    plot(EEG1.data(show_chan,300*DOWNSAMPLE_TO:302*DOWNSAMPLE_TO))
    title('After downsampling'); grid on
    xlim([1 DOWNSAMPLE_TO*2])
    EEG = EEG1;
    Fs = DOWNSAMPLE_TO;
    clear EEG1
end

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
        if strcmp(S(i).type, 'right') == 1
            Y(counter,:) = EEG.data(62,start:fin);
            startfin(counter,1:2) = [start fin];
            Z(counter) = 1;
            disp([num2str(counter) '_' S(i).type ' right, trial = ', num2str(i)])
        else
            Y(counter,:) = EEG.data(61,start:fin);
            startfin(counter,1:2) = [start fin];
            Z(counter) = 0;
            disp([num2str(counter) '_' S(i).type ' left, trial = ', num2str(i)])
        end
        start = start + STEPSIZE*Fs - 1;
        disp([num2str(start/Fs) '___' num2str((S(i).latency + TRIAL_LEN*Fs)/Fs)])
        fin = start + WINSIZE*Fs - 1;    
        disp([num2str(fin/Fs) '___' num2str((S(i).latency + TRIAL_LEN*Fs)/Fs)])
    end
end
Z = Z';

if WAVELET == 1
    
    window_len = 64; % 100
    noverlap = 50;
    nfft = 512;
    X = zeros(length(startfin), IMSIZE(1), IMSIZE(2), 3);
    for i = 1:length(startfin)
          
        for j = 1:length(CHAN_RANGE)
            [S,F,T] = spectrogram(EEG.data(CHAN_RANGE(j),startfin(i,1):startfin(i,2)),...
                window_len,noverlap,nfft,EEG.srate);
%             X(i,:,:,j) = abs([S(13:28,:); imresize(S(36:63,:), [15, 32])]).^2;
            X(i,:,:,j) = imresize((abs(S(42:97,:))).^2, [IMSIZE]);
        end
        disp(i)
    end
end

if WAVELET==0
    fileout = ['/home/amplifier/home/DATASETS/' ... 
        filein ', ' ...
        'DS2=' num2str(DOWNSAMPLE_TO) 'Hz, '...
        'FIR=' num2str(low_cutoff) '-' ...
        num2str(high_cutoff) 'Hz, ' ...
        'centnorm=', num2str(CENTER_NORMALIZE) ', ' ...
        'Env=' num2str(COMPUTE_ENVELOPE) ', '...
        'TD, ' ...
        num2str(events(1)) '-' num2str(events(end)) '.mat']
    save(fileout, 'X', 'Y', 'Z', 'WINSIZE', 'STEPSIZE', 'TRIAL_LEN')
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

if WAVELET==1
    figure
    for i = 1:size(X,4)
        subplot(1,size(X,4),i)
        imagesc(squeeze(X(465,:,:,i)))
    end
    
    fileout = ['/Users/RomanKoshkin/Downloads/' filein '->' num2str(low_cutoff) '-' num2str(high_cutoff) 'Hz,' 'Env=' num2str(COMPUTE_ENVELOPE) '_FD' '.mat']
    save(fileout, 'X', 'Y', 'Z', 'WINSIZE', 'STEPSIZE', 'TRIAL_LEN')
end

