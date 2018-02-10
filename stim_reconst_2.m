% Compared to stim_reconst_1_PARFOR.m, this code is about twice as
% efficient.

load('EEG.mat')
clearvars -except EEG ga ua
tic
%% define model parameters:
LAMBDA = 0.03;
shift_sec = [-2.75 -2.5 -2.25 -2 -1.75 -1.5 -1.25 -1 -0.75 -0.5 -0.25 0 0.25 0.5 0.75 1 1.25 1.5 1.75 2 2.25 2.5 2.75]; % vector of stimulus shifts
% shift_sec = [-1.25 -1 -0.75 -0.5 -0.25 -0.125 0 0.125 0.25 0.5]; % vector of stimulus shifts
% shift_sec = [-0.5 -0.25 -0.125 0 0.125 0.25 0.5]; % vector of stimulus shifts
% shift_sec = [-1 0];

compute_envelope = 1;
% lags start and end:
or = 0;    % kernel origin, ms % ???????????, ??? ??????, ??? ?????
en = 100;
events = 5:64; % event ordinal numbers in the 

S = struct('type', [], 'code_no', [], 'latency', [],...
    'a_r_left', [], 'u_r_left', [], 'a_r_right', [], 'u_r_right', [],...
    'a_MSE_left', [], 'u_MSE_left', [], 'a_MSE_right', '?', 'u_MSE_right', []);
ch_left = find(ismember({EEG.chanlocs.labels}, 'Left_AUX') == 1);
ch_right = find(ismember({EEG.chanlocs.labels},'Right_AUX') == 1);
Fs = EEG.srate;


% g_att = [];         % attended decoder tensor
% g_unatt = [];       % unattended decoder tensor

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
Lcon = ones(size(EEG.data, 1)-2, 1); % minus audio channels

g_att = zeros(60,en/1000*Fs+1,length(S));
g_unatt = zeros(60,en/1000*Fs+1,length(S));
% FIRST, WE TRAIN THE DECODERS (FOR UNSHIFTED STIM/RESP)
parfor j = 1:length(S) % $$$$$$$$$$$$$$$$$$$$ CHOSE EITHER PARFOR OR FOR.
    addr = S(j).code_no;
    tic
    start = round(EEG.event(addr).latency);
    fin = round(EEG.event(addr+1).latency);


    if compute_envelope == 1
        stimLeft = abs(hilbert(EEG.data(ch_left, start:fin)))';
        stimRight = abs(hilbert(EEG.data(ch_right, start:fin)))';
    else
        stimLeft = EEG.data(ch_left, start:fin)';
        stimRight = EEG.data(ch_right, start:fin)';
    end

    response = EEG.data(1:60, start:fin)';

    [wLeft,t, ~] = mTRFtrain(stimLeft, response, Fs, 1, or, en, LAMBDA);
    if strcmp (S(j).type, 'left') == 1
        % g_att = cat(3, g_att, wLeft);
        g_att(:,:,j) = wLeft;
    else
        % g_unatt = cat(3, g_unatt, wLeft);
        g_unatt(:,:,j) = wLeft;
    end


    [wRight,t, ~] = mTRFtrain(stimRight, response, Fs, 1, or, en, LAMBDA);
    if strcmp (S(j).type, 'right') == 1
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
    
% average the decoders over all the 30-second-long trials:
g_att = mean(g_att,3);
g_unatt = mean(g_unatt,3);


for sh = 1:length(shift_sec)
    
    % FOR/PARFOR
    parfor j = 1:30 % !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! ATTENTION!
  
        start = round(S(j).latency);
        fin = round(start + 30*EEG.srate); % !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! ATTENTION!
        

        if compute_envelope == 1
            stimLeft = abs(hilbert(EEG.data(ch_left, start:fin)))';
            stimRight = abs(hilbert(EEG.data(ch_right, start:fin)))';
        else
            stimLeft = EEG.data(ch_left, start:fin)';
            stimRight = EEG.data(ch_right, start:fin)';
        end

        try
            stimLeft = circshift(stimLeft, Fs*shift_sec(sh)); % !!!!!??? ??????, ??? ???????!!!!!!
            stimRight = circshift(stimRight, Fs*shift_sec(sh));% !!!!!??? ??????, ??? ???????!!!!!!
        catch
            disp(['sh = ' num2str(sh)])
        end

        response = EEG.data(1:60, start:fin)';



        [~, S(j).a_r_left, ~, S(j).a_MSE_left] = mTRFpredict(stimLeft, response, g_att, Fs, 1, or, en, Lcon);
        [~, S(j).a_r_right, ~, S(j).a_MSE_right] = mTRFpredict(stimRight, response, g_att, Fs, 1, or, en, Lcon);

        [~, S(j).u_r_left, ~, S(j).u_MSE_left] = mTRFpredict(stimLeft, response, g_unatt, Fs, 1, or, en, Lcon);
        [~, S(j).u_r_right, ~, S(j).u_MSE_right] = mTRFpredict(stimRight, response, g_unatt, Fs, 1, or, en, Lcon);
        disp(['parallel mode, iteration ' num2str(j)])
    end

    for j = 1:length(S)
        if strcmp(S(j).type,'left') == 1 & S(j).a_r_left > S(j).a_r_right...
                ||...
                strcmp(S(j).type,'right') == 1 & S(j).a_r_left < S(j).a_r_right
            S(j).a_correct = 1;
        else
            S(j).a_correct = 0;
        end
    end
    for j = 1:length(S)
        if strcmp(S(j).type,'left') == 1 & S(j).u_r_left > S(j).u_r_right...
                ||...
                strcmp(S(j).type,'right') == 1 & S(j).u_r_left < S(j).u_r_right
            S(j).u_correct = 1;
        else
            S(j).u_correct = 0;
        end
    end
    a_accuracy(sh) = mean([S(1:length(S)).a_correct]);
    u_accuracy(sh) = mean([S(1:length(S)).u_correct]);

    for j = 1:length(S)
        if strcmp(S(j).type,'right') == 1
            S(j).a_r_att = S(j).a_r_right;
            S(j).a_r_unatt = S(j).a_r_left;
        else
            S(j).a_r_att = S(j).a_r_left;
            S(j).a_r_unatt = S(j).a_r_right;
        end
    end

    for j = 1:length(S)
        if strcmp(S(j).type,'right') == 1
            S(j).u_r_att = S(j).u_r_right;
            S(j).u_r_unatt = S(j).u_r_left;
        else
            S(j).u_r_att = S(j).u_r_left;
            S(j).u_r_unatt = S(j).u_r_right;
        end
    end

    figure
    subplot(1,2,1)
    scatter([S.a_r_att], [S.a_r_unatt])
    ax = gca; ax.FontSize = 14;
    title (['ATTended decoder accuracy ' num2str(a_accuracy(sh)) ', shift = ' num2str(shift_sec(sh))])
    xlabel ('r_{attended}', 'FontSize', 20)
    ylabel ('r_{unattended}', 'FontSize', 20)
    grid on
    refline(1,0)
    pbaspect([1 1 1])
    ax.YLim = [-0.1 0.25];
    ax.XLim = [-0.1 0.25];

    subplot(1,2,2)
    scatter([S.u_r_att], [S.u_r_unatt])
    ax = gca; ax.FontSize = 14;
    title (['UNattended decoder accuracy ' num2str(u_accuracy(sh)) ', shift = ' num2str(shift_sec(sh))])
    xlabel ('r_{attended}', 'FontSize', 20)
    ylabel ('r_{unattended}', 'FontSize', 20)
    grid on
    refline(1,0)
    pbaspect([1 1 1])
    ax.YLim = [-0.1 0.25];
    ax.XLim = [-0.1 0.25];
    
    mu_Ratt(sh) = mean([S.a_r_att]);
    SEM_Ratt(sh) = std([S.a_r_att])/sqrt(length([S.a_r_att]));
    mu_Runatt(sh) = mean([S.u_r_att]);
    SEM_Runatt(sh) = std([S.u_r_att])/sqrt(length([S.u_r_att]));
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
save('output.mat', 'S', 'g_att', 'g_unatt', 'en', 'shift_sec', 'LAMBDA', 'mu_Ratt', 'mu_Runatt', 'SEM_Ratt', 'SEM_Runatt', 'a_accuracy', 'u_accuracy', 'Lcon')
toc