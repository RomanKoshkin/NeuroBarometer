% Compared to stim_reconst_1_PARFOR.m, this code is about twice as
% efficient.

% load('KOS_1+2_80Hz.mat')

load('KOS_DAS_80Hz.mat')
clearvars -except EEG
tic
%% define model parameters:
LAMBDA = 0.03;
len_win_classified = 30;
% shift_sec = [-2.75 -2.5 -2.25 -2 -1.75 -1.5 -1.25 -1 -0.75 -0.5 -0.25 0 0.25 0.5 0.75 1 1.25 1.5 1.75 2 2.25 2.5 2.75]; % vector of stimulus shifts
% shift_sec = [-1.25 -1 -0.75 -0.5 -0.25 -0.125 0 0.125 0.25 0.5]; % vector of stimulus shifts
shift_sec = [-0.5 -0.25 -0.125 0 0.125 0.25 0.5]; % vector of stimulus shifts
% shift_sec = [0];

compute_envelope = 1;
% lags start and end:
or = 0;    % kernel origin, ms % ???????????, ??? ??????, ??? ?????
en = 50;

% range of events in the EEG.event struct
events = [5:64, 75:134, 143:202]; % event ordinal numbers in the  
% events = [5:64]; % event ordinal numbers in the  

% initialize an empty struct array with ALL the necessary fields.
% Otherwise the PARFOR loops won't run.
S = struct('type', [], 'code_no', [], 'latency', [],...
    'R_LDec_LCh', [], 'R_RDec_LCh', [], 'R_LDec_RCh', [], 'R_RDec_RCh', [],...
    'MSE_LDec_LCh', [], 'MSE_RDec_LCh', [], 'MSE_LDec_RCh', [], 'MSE_RDec_RCh', [],...
    'a_accuracy', [], 'u_accuracy', [],...
    'r_Adec_Ach', [], 'r_Adec_Uch', [], 'r_Udec_Ach', [], 'r_Udec_Uch', []);

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
%%
% if you wanna get a return from the a parfor loop, you need to declare the
% variables, with the RIGHT SIZES!!!. Parfor works like a function. It only
% returns what has been declared before. If you define a var inside a
% parfor loop, it is never returned.
% Initialize vars for the parfor loop:

Lcon = ones(size(EEG.data, 1)-2, 1); % minus audio channels

% load onset latencies into S.latency:
temp = num2cell([EEG.event([S.code_no]).latency]);
[S.latency] = temp{:};

%% now split the data into two large continuous subsets (attend right, attend left)
att_right = [S(find(ismember({S.type}, 'right'))).code_no];
att_left = [S(find(ismember({S.type}, 'left'))).code_no];

respRight = [];
respLeft = [];
stimRight = [];
stimLeft = [];
for i = att_right
    start = round(EEG.event(i).latency);
    fin = start + 30*EEG.srate-1;
    respRight = cat(2, respRight, EEG.data(1:60, start:fin));
    stimRight = cat(2, stimRight, EEG.data(ch_right, start:fin));
end

for i = att_left
    start = round(EEG.event(i).latency);
    fin = start + 30*EEG.srate-1;
    respLeft = cat(2, respLeft, EEG.data(1:60,start:fin));
    stimLeft = cat(2, stimLeft, EEG.data(ch_left,start:fin));
end

respRight = respRight';
stimRight = stimRight';
respLeft = respLeft';
stimLeft = stimLeft';

% and find the decoders on these large subsets:

% ATTENDED DECODERS (ONE FOR LISTEN RIGHT, ONE FOR LEFT)
[w_RDec_RCh,t, ~] = mTRFtrain(stimRight, respRight, Fs, 1, or, en, LAMBDA);
[w_LDec_LCh,t, ~] = mTRFtrain(stimLeft, respLeft, Fs, 1, or, en, LAMBDA);

% UNATTENDED DECODERS (ONE FOR DON'T LISTEN RIGHT, ONE FOR DON'T LISTEN LEFT)
[w_LDec_RCh,t, ~] = mTRFtrain(stimRight, respLeft, Fs, 1, or, en, LAMBDA);
[w_RDec_LCh,t, ~] = mTRFtrain(stimLeft, respRight, Fs, 1, or, en, LAMBDA);

%% no
for sh = 1:length(shift_sec)
    
    parfor j = 1:length(S) % FOR/PARFOR
            
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
   
        [~, S(j).R_LDec_LCh, ~, S(j).MSE_LDec_LCh] = mTRFpredict(stimLeft, response, w_LDec_LCh, Fs, 1, or, en, Lcon); % response ???
        [~, S(j).R_RDec_RCh, ~, S(j).MSE_RDec_RCh] = mTRFpredict(stimRight, response, w_RDec_RCh, Fs, 1, or, en, Lcon);

        [~, S(j).R_RDec_LCh, ~, S(j).MSE_RDec_LCh] = mTRFpredict(stimLeft, response, w_RDec_LCh, Fs, 1, or, en, Lcon);
        [~, S(j).R_LDec_RCh, ~, S(j).MSE_LDec_RCh] = mTRFpredict(stimRight, response, w_LDec_RCh, Fs, 1, or, en, Lcon);
        
        if strcmp(S(j).type, 'right') == 1
            S(j).r_Adec_Ach = S(j).R_RDec_RCh;
            S(j).r_Adec_Uch = S(j).R_RDec_LCh;
            S(j).r_Udec_Ach = S(j).R_LDec_RCh;
            S(j).r_Udec_Uch = S(j).R_LDec_LCh;
        else
            S(j).r_Adec_Ach = S(j).R_LDec_LCh;
            S(j).r_Adec_Uch = S(j).R_LDec_RCh;
            S(j).r_Udec_Ach = S(j).R_RDec_LCh;
            S(j).r_Udec_Uch = S(j).R_RDec_RCh;
        end
        
        disp(['parallel mode, trial ' num2str(j) ' Shift ' num2str(shift_sec(sh))])
    end
    
    % compute accuracy:
    a_accuracy_tmp = num2cell(arrayfun(@(x) gt(x,0), [S.r_Adec_Ach]-[S.r_Adec_Uch]));
    [S.a_accuracy] = a_accuracy_tmp{:};
    u_accuracy_tmp = num2cell(arrayfun(@(x) gt(x,0), [S.r_Udec_Uch]-[S.r_Udec_Ach]));
    [S.u_accuracy] = u_accuracy_tmp{:};
    
    a_accuracy(sh) = mean(cellfun(@double, a_accuracy_tmp));
    u_accuracy(sh) = mean(cellfun(@double, u_accuracy_tmp));

    
    figure
    subplot(1,2,1)
    scatter([S.r_Adec_Ach], [S.r_Adec_Uch])
    ax = gca; ax.FontSize = 14;
    title (['ATTended decoder accuracy ' num2str(a_accuracy(sh)) ', shift = ' num2str(shift_sec(sh))])
    xlabel ('r_{attended chan}', 'FontSize', 20)
    ylabel ('r_{unattended chan}', 'FontSize', 20)
    grid on
    refline(1,0)
    pbaspect([1 1 1])
    ax.YLim = [-0.1 0.25];
    ax.XLim = [-0.1 0.25];

    subplot(1,2,2)
    scatter([S.r_Udec_Ach], [S.r_Udec_Uch])
    ax = gca; ax.FontSize = 14;
    title (['UNattended decoder accuracy ' num2str(u_accuracy(sh)) ', shift = ' num2str(shift_sec(sh))])
    xlabel ('r_{attended chan}', 'FontSize', 20)
    ylabel ('r_{unattended chan}', 'FontSize', 20)
    grid on
    refline(1,0)
    pbaspect([1 1 1])
    ax.YLim = [-0.1 0.25];
    ax.XLim = [-0.1 0.25];
    
    mu_Ratt(sh) = mean([S.r_Adec_Ach]);
    SEM_Ratt(sh) = std([S.r_Adec_Ach])/sqrt(length([S.r_Adec_Ach]));
    mu_Runatt(sh) = mean([S.r_Udec_Ach]);
    SEM_Runatt(sh) = std([S.r_Udec_Ach])/sqrt(length([S.r_Udec_Ach]));
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
save('output.mat', 'S', 'en', 'or', 'shift_sec', 'LAMBDA', 'mu_Ratt', 'mu_Runatt', 'SEM_Ratt', 'SEM_Runatt', 'a_accuracy', 'u_accuracy', 'Lcon')
toc
% now run real_time.m