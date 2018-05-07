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
load('/Users/RomanKoshkin/Downloads/EEG_latest/DAS_CH_AVG_500Hz.mat')
% load('/Users/RomanKoshkin/Downloads/EEG_latest/DAS_CH_AVG_500Hz_2.mat')

disp('dataset loaded')
clearvars -except EEG
tic

%% define model parameters:
ST =                    'right' % with which channel to correlate
LAMBDA =                0.47;
len_win_classified =    60;
compute_envelope =      1;
center_normalize =      1;
filtering =             1;
RESAMPLE =              1;
low_cutoff =            1;
high_cutoff =           9;
DOWNSAMPLE_TO =         64;
AUDIO_PREPROC =         1;
% lags start and end:
or = 0;    % kernel origin, ms % ???????????, ??? ??????, ??? ?????
en = 500;

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

% test_events = train_events

Lcon = zeros(size(EEG.data, 1)-2, 1); % minus audio channels

% initialize a correctly-sized matrix of nans:

g = [];

% FIRST, WE TRAIN DECODERS ON TRAINING TRIALS:
for j = 1:40 % $$$$$$$$$$$$$$$$$$$$ CHOSE EITHER PARFOR OR FOR.
    addr = code_nos(j);
    tic
    start = round(EEG.event(addr).latency);
    fin = round(start + len_win_classified*EEG.srate);

    stim = EEG.data(ST, start:fin)';

    response = EEG.data(1:63, start:fin)';

    [G, t, ~] = mTRFtrain(stim, response, Fs, 1, or, en, LAMBDA);
    
%     if strcmp (S(find(ismember([S.code_no], addr))).type, 'russian') == 1
    g = cat(3, g, G);
    
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

R_nos = find(ismember({S.type}, 'russian'));
F_nos = find(ismember({S.type}, 'foreign'));

% CROSS-VALIDATE:
for j = 1:length(code_nos) % FOR/PARFOR

    start = round(EEG.event(code_nos(j)).latency);
    fin = round(start + len_win_classified*EEG.srate);

    stim = EEG.data(ST, start:fin)';
    response = EEG.data(1:63, start:fin)';
    
    g_tmp = g;
    g_tmp(:,:,j) = NaN;
    
    g_att_tmp = nanmean(g_tmp(:,:,R_nos),3);
    g_unatt_tmp = nanmean(g_tmp(:,:,F_nos),3);
        
       
    [a_X, S(j).a_r, ~, ~] = mTRFpredict(stim, response, g_att_tmp, Fs, 1, or, en, Lcon);
%     [d,Z,tr] = procrustes(stim, a_X);
%     S(s_addr).a_immse = immse(stim,Z);
    
    [u_X, S(j).u_r, ~, ~] = mTRFpredict(stim, response, g_unatt_tmp, Fs, 1, or, en, Lcon);
%     [d,Z,tr] = procrustes(stim, u_X);
%     S(s_addr).u_immse = immse(stim,Z);
    
    disp(['parallel mode, trial ' num2str(j)])
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

a_accuracy = sum([S.r_success])/length(code_nos);
clc
disp(['Accuracy = ' num2str(a_accuracy)])
disp(['Mean corr on Russian lang. = ' num2str(mean([S.a_r]))])
disp(['Mean corr on foreign lang. = ' num2str(mean([S.u_r]))])


error('CODE EXECUTION FINISHED')
%%
figure('units','normalized','outerposition',[0 0 1 1])
subplot(1,2,1)
plot(1:length(shift_sec), a_accuracy, 1:length(shift_sec), u_accuracy, 'LineWidth', 3)
ax = gca;
ax.XTick = 1:length(shift_sec);
ax.XTickLabels = {shift_sec};
title(['Filtered/UNReferenced, Kernel = ' num2str(en) ' \lambda = ' num2str(LAMBDA)], 'FontSize', 14)
legend({'attended accuracy', 'unattended accuracy'}, 'FontSize', 12)
ylabel ('Classification accuracy', 'FontSize', 16)
xlabel ('Stimulus shift relative to real time', 'FontSize', 16)
grid on

subplot(1,2,2)
errorbar(1:length(shift_sec), mu_Ratt, 1.98*SEM_Ratt, 'LineWidth', 3)
hold on
errorbar(1:length(shift_sec), mu_Runatt, 1.98*SEM_Runatt, 'LineWidth', 3)
ax = gca;
ax.XTick = 1:length(shift_sec);
ax.XTickLabels = {shift_sec};
title(['Correlation vs. Time Shift, Kernel = ' num2str(en) ' \lambda = ' num2str(LAMBDA) ' (bars show 95%-CIs (1.98*SEM))'], 'FontSize', 14)
legend({'R_{attended}', 'R_{unattended}'}, 'FontSize', 12)
ylabel ('Pearsons R', 'FontSize', 16)
xlabel ('Stimulus shift relative to real time', 'FontSize', 16)
grid on
save('output.mat', 'S', 'g_att', 'g_unatt', 'en', 'or', 'shift_sec', 'LAMBDA', 'mu_Ratt', 'mu_Runatt', 'SEM_Ratt', 'SEM_Runatt', 'a_accuracy', 'u_accuracy', 'Lcon')
toc
% now run real_time.m