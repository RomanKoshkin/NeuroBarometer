% Compared to stim_reconst_1_PARFOR.m, this code is about twice as
% efficient.

load('KOS_DAS_80Hz.mat')
clearvars -except EEG
tic
%% define model parameters:
LAMBDA = 0.03;
len_win_classified = 30;
% shift_sec = [-2.75 -2.5 -2.25 -2 -1.75 -1.5 -1.25 -1 -0.75 -0.5 -0.25 0 0.25 0.5 0.75 1 1.25 1.5 1.75 2 2.25 2.5 2.75]; % vector of stimulus shifts
shift_sec = [-1.25 -1 -0.75 -0.5 -0.25 -0.125 0 0.125 0.25 0.5]; % vector of stimulus shifts
% shift_sec = [-0.5 -0.25 -0.125 0 0.125 0.25 0.5]; % vector of stimulus shifts
% shift_sec = [-1 0 1];

compute_envelope = 1;
% lags start and end:
or = 0;    % kernel origin, ms % ???????????, ??? ??????, ??? ?????
en = 500;

% range of events in the EEG.event struct
% events = [5:64, 75:134, 143:202, 211:299, 308:396, 405:493]; % event ordinal numbers in the  
% events = [5:64, 75:134, 143:202]; % event ordinal numbers in the  
events = [143:202];
% initialize an empty struct array to store results:
S = struct('type', [], 'code_no', [], 'latency', [],...
    'a_r_left', [], 'u_r_left', [], 'a_r_right', [], 'u_r_right', [],...
    'a_correct', [], 'u_correct', [], ...
    'a_MSE_left', [], 'u_MSE_left', [], 'a_MSE_right', '?', 'u_MSE_right', []);
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


% if you wanna get a return from the a parfor loop, you need to declare the
% variables, with the RIGHT SIZES!!!. Parfor works like a function. It only
% returns what has been declared before. If you define a var inside a
% parfor loop, it is never returned.
% Initialize vars for the parfor loop:
Lcon = ones(size(EEG.data, 1)-2, 1); % minus audio channels
% g_att = zeros(60,(en-or)/1000*Fs+1,length(S));
% g_unatt = zeros(60,(en-or)/1000*Fs+1,length(S));

% FIRST, WE TRAIN THE DECODERS (FOR UNSHIFTED STIM/RESP)
counter = 0;
for j = 1:length(S) % $$$$$$$$$$$$$$$$$$$$ CHOSE EITHER PARFOR OR FOR.
    addr = S(j).code_no;
    tic
    start = round(EEG.event(addr).latency);
    fin = round(start + len_win_classified*EEG.srate);

    if compute_envelope == 1
        stimLeft = abs(hilbert(EEG.data(ch_left, start:fin)))';
        stimRight = abs(hilbert(EEG.data(ch_right, start:fin)))';
    else
        stimLeft = EEG.data(ch_left, start:fin)';
        stimRight = EEG.data(ch_right, start:fin)';
    end

    response = EEG.data(1:60, start:fin)';

    [wLeft,t, ~] = mTRFtrain(stimLeft, response, Fs, 1, or, en, LAMBDA);
    [wRight,t, ~] = mTRFtrain(stimRight, response, Fs, 1, or, en, LAMBDA);
    
    % if out current trial is 'listen left', then the decoder
    % for which the stimulus is the LEFT channel, is considered ATTENDED (g_att) 
    if strcmp (S(j).type, 'left') == 1
%         counter = counter + 1;
%         g_att(:,:,counter) = wLeft;
%         g_unatt(:,:,counter) = wRight;
    else
        % if out current trial is 'listen right', then the decoder
        % for which the stimulus is the RIGHT channel, is considered ATTENDED (g_att)
        counter = counter + 1;
        g_att(:,:,counter) = wRight;
        g_unatt(:,:,counter) = wLeft;
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
    
% average the decoders over all the 30-second-long trials:
% if we decode an unknown trial using g_att, then we should get a higher
% correlation with the left channel (which means that it was a 'listen
% left' trial), than with the right channel ??????

g_att = mean(g_att,3);
g_unatt = mean(g_unatt,3);


for sh = 1:length(shift_sec)
    
    % now use the average decoders to predict what's what: 
    for j = 1:length(S) % FOR/PARFOR
  
        start = round(S(j).latency);
        fin = round(start + len_win_classified*EEG.srate);
        
        if compute_envelope == 1
            stimLeft = abs(hilbert(EEG.data(ch_left, start:fin)))';
            stimRight = abs(hilbert(EEG.data(ch_right, start:fin)))';
        else
            stimLeft = EEG.data(ch_left, start:fin)';
            stimRight = EEG.data(ch_right, start:fin)';
        end

        try
            stimLeft = circshift(stimLeft, Fs*shift_sec(sh)); 
            stimRight = circshift(stimRight, Fs*shift_sec(sh));
        catch
            disp(['sh = ' num2str(sh)])
        end

        response = EEG.data(1:60, start:fin)';


        [~, S(j).a_r_left, ~, S(j).a_MSE_left] = mTRFpredict(stimLeft, response, g_att, Fs, 1, or, en, Lcon);
        [~, S(j).a_r_right, ~, S(j).a_MSE_right] = mTRFpredict(stimRight, response, g_att, Fs, 1, or, en, Lcon);

        [~, S(j).u_r_left, ~, S(j).u_MSE_left] = mTRFpredict(stimLeft, response, g_unatt, Fs, 1, or, en, Lcon);
        [~, S(j).u_r_right, ~, S(j).u_MSE_right] = mTRFpredict(stimRight, response, g_unatt, Fs, 1, or, en, Lcon);
        disp(['parallel mode, trial ' num2str(j) ' Shift ' num2str(shift_sec(sh))])
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
    
    a_accuracy(sh) = mean([S.a_correct]);
    u_accuracy(sh) = mean([S.u_correct]);
    
    [CIlo, CIhi] = AgrestiCoullCI(sum([S.a_correct]), length([S.a_correct]), 0.05);
    a_CI(1,sh) = CIlo;
    a_CI(2,sh) = CIhi;
    
end

a_accuracy
u_accuracy
toc

errorbar(1:length(shift_sec), a_accuracy, a_CI(1,:)-a_accuracy, a_CI(2,:)-a_accuracy, 'LineWidth', 3)
plot(1:length(shift_sec), a_accuracy, 1:length(shift_sec), u_accuracy, 'LineWidth', 3)
ax = gca;
ax.XTick = 1:length(shift_sec);
ax.XTickLabels = {shift_sec};
title(['Filtered/UNReferenced, Kernel = ' num2str(en) ' \lambda = ' num2str(LAMBDA)], 'FontSize', 14)
legend({'attended accuracy', 'unattended accuracy'}, 'FontSize', 12)
ylabel ('Classification accuracy', 'FontSize', 16)
xlabel ('Stimulus shift relative to real time', 'FontSize', 16)
grid on