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
% shift_sec = [-0.5 -0.25 -0.125 0 0.125 0.25 0.5]; % vector of stimulus shifts
shift_sec = [0];

compute_envelope = 1;
% lags start and end:
or = 0;    % kernel origin, ms % ???????????, ??? ??????, ??? ?????
en = 50;

% range of events in the EEG.event struct
% events = [5:64, 75:134, 143:202]; % event ordinal numbers in the  
events = [5:64]; % event ordinal numbers in the  

% initialize an empty struct array with ALL the necessary fields.
% Otherwise the PARFOR loops won't run.
S = struct('type', [], 'code_no', [], 'latency', [],...
    'R_Att', [], 'R_Unatt', [],...
    'MSE_Att', [], 'MSE_Unatt', [],...
    'a_accuracy', [], 'u_accuracy', []);

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
[wRight,t, ~] = mTRFtrain(stimRight, respRight, Fs, 1, or, en, LAMBDA);
[wLeft,t, ~] = mTRFtrain(stimLeft, respLeft, Fs, 1, or, en, LAMBDA);

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
        
        if strcmp(S(j).type, 'right') == 1
            [~, S(j).R_Att, ~, S(j).MSE_Att] = mTRFpredict(stimRight, response, wRight, Fs, 1, or, en, Lcon);
            [~, S(j).R_Unatt, ~, S(j).MSE_Unatt] = mTRFpredict(stimLeft, response, wRight, Fs, 1, or, en, Lcon);
        else
            [~, S(j).R_Att, ~, S(j).MSE_Att] = mTRFpredict(stimLeft, response, wLeft, Fs, 1, or, en, Lcon);
            [~, S(j).R_Unatt, ~, S(j).MSE_Unatt] = mTRFpredict(stimRight, response, wLeft, Fs, 1, or, en, Lcon);
        end
        
        
        disp(['parallel mode, trial ' num2str(j) ' Shift ' num2str(shift_sec(sh))])
    end
    
    % compute accuracy:
    a_accuracy_tmp = num2cell(arrayfun(@(x) gt(x,0), [S.R_Att]-[S.R_Unatt]));
    [S.a_accuracy] = a_accuracy_tmp{:};
    
    a_accuracy(sh) = mean(cellfun(@double, a_accuracy_tmp));

    
    figure
    scatter([S.R_Att], [S.R_Unatt])
    ax = gca; ax.FontSize = 14;
    title (['ATTended decoder accuracy ' num2str(a_accuracy(sh)) ', shift = ' num2str(shift_sec(sh))])
    xlabel ('r_{attended chan}', 'FontSize', 20)
    ylabel ('r_{unattended chan}', 'FontSize', 20)
    grid on
    refline(1,0)
    pbaspect([1 1 1])
    ax.YLim = [-0.1 0.25];
    ax.XLim = [-0.1 0.25];
  
    mu_Ratt(sh) = mean([S.R_Att]);
    SEM_Ratt(sh) = std([S.R_Att])/sqrt(length([S.R_Att]));
    mu_Runatt(sh) = mean([S.R_Unatt]);
    SEM_Runatt(sh) = std([S.R_Unatt])/sqrt(length([S.R_Unatt]));
end

%%
figure('units','normalized','outerposition',[0 0 1 1])
subplot(1,2,1)
plot(1:length(shift_sec), a_accuracy, 'LineWidth', 3)
ax = gca;
ax.XTick = 1:length(shift_sec);
ax.XTickLabels = {shift_sec};
title(['Filtered/UNReferenced, Kernel = ' num2str(en) ' \lambda = ' num2str(LAMBDA)], 'FontSize', 14)
legend({'attended accuracy'}, 'FontSize', 12)
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
% legend({'R_{attended}', 'R_{unattended}'}, 'FontSize', 12)
ylabel ('Pearsons R', 'FontSize', 16)
xlabel ('Stimulus shift relative to real time', 'FontSize', 16)
grid on
save('output.mat', 'S', 'en', 'or', 'shift_sec', 'LAMBDA', 'mu_Ratt', 'mu_Runatt', 'SEM_Ratt', 'SEM_Runatt', 'a_accuracy', 'Lcon')
toc
% now run real_time.m