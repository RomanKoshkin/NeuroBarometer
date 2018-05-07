%
% THE DATASET IS NOT REFERENCED!!!
% 

clear
eeglab redraw

filepath = '/Volumes/Transcend/NeuroBarometer/';
% filein = 'Merged456_197-298_protocol_1.set';
filein = 'Merged456_197-298.set';

EEG = pop_loadset([filepath filein]);
eeglab redraw

%%
train_test_split =      0.8;    % proportion of train/test samples
train_test_split_RANDOM = 1;    % do we sample train/test sampels randomly?
LAMBDA =                0.47;
len_win_classified =    30;

CHAN_RANGE = 1:size(EEG.data,1)-2;
AUDIO_PREPROC = 1;
COMPUTE_ENVELOPE = 1;
DOWNSAMPLING = 1;
DOWNSAMPLE_TO = 64;
CENTER_NORMALIZE = 0;
FILTER_ALL = 1;
    low_cutoff = 1;
    high_cutoff = 30;
TRIAL_LEN = 30; % what's the duration of a trial

or = 0;    % kernel origin, ms % ???????????, ??? ??????, ??? ?????
en = 300;

events = 1:length(EEG.event);

% initialize an empty struct array to store results:
S = struct('type', [], 'code_no', [], 'latency', [],...
    'a_r_right', [], 'u_r_left', [],...
    'a_r_left', [], 'u_r_right', []);
ch_left = find(ismember({EEG.chanlocs.labels}, 'Left_AUX') == 1);
ch_right = find(ismember({EEG.chanlocs.labels},'Right_AUX') == 1);
Fs = EEG.srate;

if AUDIO_PREPROC == 1
    figure; plot (EEG.data(62, 80000:90000)); hold on
    EEG.data(ch_left:ch_right,:) = highpassFIR(EEG.data(ch_left:ch_right,:), Fs, 1, 3, 0);
    plot (EEG.data(62, 80000:90000)); title('Audio before and after highpass filtering');
    EEG.data(ch_right,:) = EEG.data(ch_right,:)/std(EEG.data(ch_right,:));
    EEG.data(ch_left,:) = EEG.data(ch_left,:)/std(EEG.data(ch_left,:));
    figure; plot (EEG.data(62, 80000:90000)); hold on;
    EEG.data(ch_left:ch_right,:) = bandpassFIR(EEG.data(ch_left:ch_right,:), Fs, 150, 170, 100, 95, 105, 0);
    plot (EEG.data(62, 80000:90000)); title('z-transformed, bandpass-filtered (~100-150 Hz, F_{0} audio before and after highpass filtering');
    audio = EEG.data(ch_left:ch_right,:);
end

if COMPUTE_ENVELOPE == 1
    EEG.data(ch_left,:) = envelope(EEG.data(ch_left,:));
    EEG.data(ch_right,:) = envelope(EEG.data(ch_right,:));
    audio = EEG.data(ch_left:ch_right,:);
end
    
if CENTER_NORMALIZE==1
    EEG.data = EEG.data-repmat(mean(EEG.data,2),1,size(EEG.data,2));
    STD = std(EEG.data,0, 2);
    for i = 1:size(EEG.data,1)
        EEG.data(i,:) = EEG.data(i,:)/STD(i,:);
    end
end

if FILTER_ALL == 1
    [EEG, ~, ~] = pop_eegfiltnew(EEG, low_cutoff, high_cutoff);
    % put the band-pass filtered, enveloped audio back into the dataset:
    EEG.data(ch_left:ch_right,:) = audio;
end

if DOWNSAMPLING == 1
    show_chan = 13;
    disp(['DOWNSAMPLING to ' num2str(DOWNSAMPLE_TO) ' Hz....'])
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

% if you wanna get a return from the a parfor loop, you need to declare the
% variables, with the RIGHT SIZES!!!. Parfor works like a function. It only
% returns what has been declared before. If you define a var inside a
% parfor loop, it is never returned.
% Initialize vars for the parfor loop:
Lcon = zeros(size(EEG.data, 1)-2, 1); % minus audio channels
[g,t, ~] = mTRFtrain(rand(1000,1), rand(1000, size(EEG.data,1)-2), Fs, 1, or, en, LAMBDA);
sz = size(g);
g_att = nan(sz(1), sz(2), length(train_events)); 
g_unatt = nan(sz(1), sz(2), length(train_events));
clear sz g t

% FIRST, WE TRAIN DECODERS (FOR UNSHIFTED STIM/RESP) ON TRAINING TRIALS:
for j = 1:length(train_events) % $$$$$$$$$$$$$$$$$$$$ CHOSE EITHER PARFOR OR FOR.
    addr = train_events(j);
    tic
    start = round(EEG.event(addr).latency);
    fin = round(start + len_win_classified*EEG.srate);

    stimLeft = EEG.data(ch_left, start:fin)';
    stimRight = EEG.data(ch_right, start:fin)';
    
    response = EEG.data(1:60, start:fin)';

    [wLeft,t, ~] = mTRFtrain(stimLeft, response, Fs, 1, or, en, LAMBDA);
    [wRight,t, ~] = mTRFtrain(stimRight, response, Fs, 1, or, en, LAMBDA);
    
    if strcmp (S(find(ismember([S.code_no], addr))).type, 'left') == 1
        disp('left')
%         g_att = cat(3, g_att, wLeft);
        g_att(:,:,j) = wLeft;
        g_unatt(:,:,j) = wRight;
    else
%         g_unatt = cat(3, g_unatt, wLeft);
        disp('right')
        g_att(:,:,j) = wRight;
        g_unatt(:,:,j) = wLeft;
    end

    % report progress:
    elapsed_time = toc;
    disp(['Computing decoder from trial:' num2str(j)...
                 ' seconds'...
                ' Kernel length: ' num2str(en) ' Elapsed: '...
                num2str(elapsed_time)])
end
    
% average the decoders over all the TRAINING 30-second-long trials:
g_att = mean(g_att,3);
g_unatt = mean(g_unatt,3);


  
for j = 1:length(test_events) % FOR/PARFOR

    addr = test_events(j);
    start = round(EEG.event(addr).latency);
    fin = round(start + len_win_classified*EEG.srate);

    stimLeft = EEG.data(ch_left, start:fin)';
    stimRight = EEG.data(ch_right, start:fin)';

    response = EEG.data(1:60, start:fin)';

    s_addr = find(ismember([S.code_no], addr));
    [~, S(s_addr).a_r_left, ~, ~] = mTRFpredict(stimLeft, response, g_att, Fs, 1, or, en, Lcon);
    [~, S(s_addr).a_r_right, ~, ~] = mTRFpredict(stimRight, response, g_att, Fs, 1, or, en, Lcon);

    [~, S(s_addr).u_r_left, ~, ~] = mTRFpredict(stimLeft, response, g_unatt, Fs, 1, or, en, Lcon);
    [~, S(s_addr).u_r_right, ~, ~] = mTRFpredict(stimRight, response, g_unatt, Fs, 1, or, en, Lcon);
    disp(['parallel mode, trial ' num2str(j)])
end
    % compute the accuracy of attended decoders:
    for j = 1:length(S)
        if strcmp(S(j).type,'right') == 1
            if S(j).a_r_right > S(j).a_r_left
                S(j).a_correct = 1;
            else
                S(j).a_correct = 0;
            end
        end
        if strcmp(S(j).type,'left') == 1
            if S(j).a_r_left > S(j).a_r_right
                S(j).a_correct = 1;
            else
                S(j).a_correct = 0;
            end
        end
    end
    
    % compute the accuracy of UNattended decoders:
    for j = 1:length(S)
        if strcmp(S(j).type,'right') == 1
            if S(j).u_r_right < S(j).u_r_left
                S(j).u_correct = 1;
            else
                S(j).u_correct = 0;
            end
        end
        if strcmp(S(j).type,'left') == 1
            if S(j).u_r_left < S(j).u_r_right
                S(j).u_correct = 1;
            else
                S(j).u_correct = 0;
            end
        end
    end
    
%     a_accuracy(sh) = sum([S.a_correct])/length(test_events);
%     u_accuracy(sh) = sum([S.u_correct])/length(test_events);
    
    % enter the direction as predicted by the ATTENDED mean decoder:
    for i = 1:length(S)
        if S(i).a_r_right>S(i).a_r_left
            S(i).a_pred_dir = 'right';
        else
            S(i).a_pred_dir = 'left';
        end
    end
