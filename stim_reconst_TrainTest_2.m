% Compared to stim_reconst_1_PARFOR.m, this code is about twice as
% efficient.

% load('KOS_1+2_80Hz.mat')

load('KOS_DAS_80Hz.mat') % DOWNLOAD HERE: https://drive.google.com/open?id=1-hwYUvl5iKi9DZGY2QusjM4cmL3EWh0C
clearvars -except EEG
tic
%% define model parameters:
LAMBDA = 0.03;
len_win_classified = 30;
% shift_sec = [-2.75 -2.5 -2.25 -2 -1.75 -1.5 -1.25 -1 -0.75 -0.5 -0.25 0 0.25 0.5 0.75 1 1.25 1.5 1.75 2 2.25 2.5 2.75]; % vector of stimulus shifts
% shift_sec = [-1.25 -1 -0.75 -0.5 -0.25 -0.125 0 0.125 0.25 0.5]; % vector of stimulus shifts
% shift_sec = [-0.5 -0.25 -0.125 0 0.125 0.25 0.5]; % vector of stimulus shifts
shift_sec = [0];
train_test_split = .75;
compute_envelope = 1;

% lags start and end:
or = 0;    % kernel origin, ms % ???????????, ??? ??????, ??? ?????
en = 1000;

% range of events in the EEG.event struct
% events = [5:64, 75:134, 143:202]; % event ordinal numbers in the  
events = [5:64]; % event ordinal numbers in the  



% initialize an empty struct array to store results:
S = struct('type', [], 'code_no', [], 'latency', [],...
    'a_r_left', [], 'u_r_left', [], 'a_r_right', [], 'u_r_right', [],...
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


% split our windows into training and testing based on our train/test split
code_nos = [S.code_no];
train_events = randsample(code_nos, round(length([S.code_no])*train_test_split));
test_events = code_nos(~ismember(code_nos, train_events))
% test_events = train_events;


% if you wanna get a return from the a parfor loop, you need to declare the
% variables, with the RIGHT SIZES!!!. Parfor works like a function. It only
% returns what has been declared before. If you define a var inside a
% parfor loop, it is never returned.
% Initialize vars for the parfor loop:
Lcon = ones(size(EEG.data, 1)-2, 1); % minus audio channels
g_att = zeros(60,(en-or)/1000*Fs+1, length(train_events));
g_unatt = zeros(60,(en-or)/1000*Fs+1,length(train_events));


% FIRST, WE TRAIN DECODERS (FOR UNSHIFTED STIM/RESP) ON TRAINING TRIALS:
parfor j = 1:length(train_events) % $$$$$$$$$$$$$$$$$$$$ CHOSE EITHER PARFOR OR FOR.
    addr = train_events(j);
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
    if strcmp (S(find(ismember([S.code_no], addr))).type, 'left') == 1
        % g_att = cat(3, g_att, wLeft);
        g_att(:,:,j) = wLeft;
    else
        % g_unatt = cat(3, g_unatt, wLeft);
        g_unatt(:,:,j) = wLeft;
    end


    [wRight,t, ~] = mTRFtrain(stimRight, response, Fs, 1, or, en, LAMBDA);
    if strcmp (S(find(ismember([S.code_no], addr))).type, 'right') == 1
        % g_att = cat(3, g_att, wRight);
        g_att(:,:,j) = wRight;
    else
        % g_unatt = cat(3, g_unatt, wRight);
        g_unatt(:,:,j) = wRight;
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
g_att = mean(g_att,3);
g_unatt = mean(g_unatt,3);


for sh = 1:length(shift_sec)
    
    for j = 1:length(test_events) % FOR/PARFOR
  
        addr = test_events(j);
        start = round(EEG.event(addr).latency);
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

        s_addr = find(ismember([S.code_no], addr));
        [~, S(s_addr).a_r_left, ~, S(s_addr).a_MSE_left] = mTRFpredict(stimLeft, response, g_att, Fs, 1, or, en, Lcon);
        [~, S(s_addr).a_r_right, ~, S(s_addr).a_MSE_right] = mTRFpredict(stimRight, response, g_att, Fs, 1, or, en, Lcon);

        [~, S(s_addr).u_r_left, ~, S(s_addr).u_MSE_left] = mTRFpredict(stimLeft, response, g_unatt, Fs, 1, or, en, Lcon);
        [~, S(s_addr).u_r_right, ~, S(s_addr).u_MSE_right] = mTRFpredict(stimRight, response, g_unatt, Fs, 1, or, en, Lcon);
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
    
    a_accuracy(sh) = sum([S.a_correct])/length(test_events);
    u_accuracy(sh) = sum([S.u_correct])/length(test_events);
    
    % enter the direction as predicted by the ATTENDED mean decoder:
    for i = 1:length(S)
        if S(i).a_r_right>S(i).a_r_left
            S(i).a_pred_dir = 'right';
        else
            S(i).a_pred_dir = 'left';
        end
    end
    
    
end

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