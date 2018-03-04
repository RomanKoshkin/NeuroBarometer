% load('KOS_DAS_80Hz_1.mat')
load('Merged123_ICA.mat')
% load('new_kos_das.mat') % MIN-MAX NORMALIZED, ENVELOPE'D, FILTFILT'D
% load('Merged123_noICA.mat')
% load('BIG.mat')

clearvars -except EEG
tic

LAMBDA = 0.05;
len_win_classified = 30;

train_test_split = 0 % set zero if you want the training and testing set to be the same

% lowpass filter design for the audio:
compute_envelope = 1;
filter_audio = 0;
    stopband = 8.5;
    passband = 8;
    order = 1000;

    % lags start and end:
or = 0;    % kernel origin, ms %
en = 200;

% range of events in the EEG.event struct
% events = [5:64, 75:134, 143:202, 211:299, 308:396, 405:493]; % event ordinal numbers in the  
% events = [5:64]; % event ordinal numbers in the  
events = [5:64, 75:134, 143:202];
% initialize an empty struct array to store results:
S = struct('type', [], 'code_no', [], 'latency', [],...
    'a_r_right', [], 'u_r_left', [],...
    'a_r_left', [], 'u_r_right', []);
ch_left = find(ismember({EEG.chanlocs.labels}, 'Left_AUX') == 1);
ch_right = find(ismember({EEG.chanlocs.labels},'Right_AUX') == 1);
Fs = EEG.srate;

if filter_audio == 1
    [l, r] = filt_audio(EEG.data(ch_left,:), EEG.data(ch_right,:), Fs, stopband, passband, order);
    figure; plot(EEG.data(61,1000:1300));hold on;plot(l(1000:1300))
    EEG.data(ch_left,:) = l;
    EEG.data(ch_right,:) = r;
    
end
  
% minmax normalize:
% EEG.data(ch_left,:) = mapminmax(EEG.data(ch_left,:),-1,1);
% EEG.data(ch_right,:) = mapminmax(EEG.data(ch_right,:),-1,1);

if compute_envelope == 1
%     EEG.data(ch_left,:) = abs(hilbert(EEG.data(ch_left,:)));
%     EEG.data(ch_right,:) = abs(hilbert(EEG.data(ch_right,:)));
    EEG.data(ch_left,:) = envelope(EEG.data(ch_left,:));
    EEG.data(ch_right,:) = envelope(EEG.data(ch_right,:));
    plot(EEG.data(61,1000:1300), 'LineWidth', 3)
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

if train_test_split == 0
    disp('The training set is equal to the tesing set')
    training_data_idx = 1:length(S); 
    testing_data_idx = 1:length(S);
else
    training_data_idx = 1:round(length(S)*train_test_split);
    testing_data_idx = find(~ismember(1:length(S),training_data_idx));
    disp(['training: ' num2str(training_data_idx)])
    disp(['testing:  ' num2str(testing_data_idx)])
end

% Initialize vars for the parfor loop:
Lcon = ones(size(EEG.data, 1)-2, 1); % minus audio channels
A_left = NaN(60,(en-or)/1000*Fs + 1, length(S));
U_left = NaN(60,(en-or)/1000*Fs + 1, length(S));
A_right = NaN(60,(en-or)/1000*Fs + 1, length(S));
U_right = NaN(60,(en-or)/1000*Fs + 1, length(S));

% FIRST, WE TRAIN THE DECODERS
parfor j = training_data_idx
    addr = S(j).code_no;
    tic
    start = round(EEG.event(addr).latency);
    fin = round(start + len_win_classified*EEG.srate);

    
    stimLeft = EEG.data(ch_left, start:fin)';
    stimRight = EEG.data(ch_right, start:fin)';

    response = EEG.data(1:60, start:fin)';

    if strcmp(S(j).type, 'right')==1
        [a_right,t, ~] = mTRFtrain(stimRight, response, Fs, 1, or, en, LAMBDA);
        [u_left,t, ~] = mTRFtrain(stimLeft, response, Fs, 1, or, en, LAMBDA);
        A_right(:,:,j) = a_right;
        U_left(:,:,j) = u_left;
    else
        [a_left,t, ~] = mTRFtrain(stimLeft, response, Fs, 1, or, en, LAMBDA);
        [u_right,t, ~] = mTRFtrain(stimRight, response, Fs, 1, or, en, LAMBDA);
        A_left(:,:,j) = a_left;
        U_right(:,:,j) = u_right;
    end

    % report progress:
    elapsed_time = toc;
    disp(['Computing decoder from trial:' num2str(j) ' seconds'...
                ' Kernel length: ' num2str(en-or)...
                ' Elapsed: ' num2str(elapsed_time)])
end

% load onset latencies into S.latency:
temp = num2cell([EEG.event([S.code_no]).latency]);
[S.latency] = temp{:};

% average the decoders:
A_left = mean(A_left,3, 'omitnan');
A_right = mean(A_right,3, 'omitnan');
U_left = mean(U_left,3, 'omitnan');
U_right = mean(U_right,3, 'omitnan');

% now use the average decoders to predict what's what in the test set: 

parfor j = testing_data_idx % FOR/PARFOR

    start = round(S(j).latency);
    fin = round(start + len_win_classified*EEG.srate);
    
    stimLeft = EEG.data(ch_left, start:fin)';
    stimRight = EEG.data(ch_right, start:fin)';
        
    response = EEG.data(1:60, start:fin)';

    [~, S(j).a_r_right, ~, ~] = mTRFpredict(stimRight, response, A_right, Fs, 1, or, en, Lcon);
    [~, S(j).a_r_left, ~, ~] = mTRFpredict(stimLeft, response, A_left, Fs, 1, or, en, Lcon);
    
    [~, S(j).u_r_right, ~, ~] = mTRFpredict(stimLeft, response, U_right, Fs, 1, or, en, Lcon);
    [~, S(j).u_r_left, ~, ~] = mTRFpredict(stimRight, response, U_left, Fs, 1, or, en, Lcon);

    disp(['parallel mode, trial ' num2str(j)])
end
clc
toc

% enter the model ATTENDED DECODER prediction into the table:
for i = 1:length(S)
    if S(i).a_r_right > S(i).a_r_left
        S(i).a_prediction = 'right';
    else
        S(i).a_prediction = 'left';
    end
end

% check if ATTENDED DECODER prediction matches the ground truth:
temp = num2cell(strcmp({S.type}, {S.a_prediction}));
[S.a_success] = temp{:};

% enter the model UNATTENDED DECODER prediction into the table:
for i = 1:length(S)
    if S(i).u_r_right < S(i).u_r_left
        S(i).u_prediction = 'right';
    else
        S(i).u_prediction = 'left';
    end
end

% check if UNATTENDED DECODER prediction matches the ground truth:
temp = num2cell(strcmp({S.type}, {S.u_prediction}));
[S.u_success] = temp{:};


disp(['Model accuracy (attended decoders): ' num2str(mean([S.a_success]))])
disp(['Model accuracy (unattended decoders): ' num2str(mean([S.u_success]))])