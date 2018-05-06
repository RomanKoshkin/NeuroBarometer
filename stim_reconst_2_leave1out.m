% Compared to stim_reconst_1_PARFOR.m, this code is about twice as
% efficient.

% load('KOS_1+2_80Hz.mat')

% load('BIG.mat')
load('Merged123_ICA.mat')
clearvars -except EEG
tic
%% define model parameters:
LAMBDA = 0.19;
len_win_classified =    30;
compute_envelope =      1;
center_normalize =      1;
filtering =             1;
low_cutoff =            1;
high_cutoff =           10;
% lags start and end:
or = 0;    % kernel origin, ms % ???????????, ??? ??????, ??? ?????
en = 500;

% range of events in the EEG.event struct
% events = [5:64, 75:134, 143:202];     % Merged123
% events = [1:94], [101:192], [197:289] % Merged456
events = [1:94];

%% 
if center_normalize == 1
    EEG.data = EEG.data-repmat(mean(EEG.data,2),1,size(EEG.data,2));
    EEG.data = EEG.data./std(EEG.data,0, 2);
end
if filtering == 1
    [EEG, ~, ~] = pop_eegfiltnew(EEG, low_cutoff, high_cutoff);
end
if compute_envelope == 1
    EEG.data(61,:) = envelope(EEG.data(61,:));
    EEG.data(62,:) = envelope(EEG.data(62,:));        
end

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

% load onset latencies into S.latency:
temp = num2cell([EEG.event([S.code_no]).latency]);
[S.latency] = temp{:};


% if you wanna get a return from the a parfor loop, you need to declare the
% variables, with the RIGHT SIZES!!!. Parfor works like a function. It only
% returns what has been declared before. If you define a var inside a
% parfor loop, it is never returned.
% Initialize vars for the parfor loop:

G_ATT = [];
G_UNATT = [];
LCON_ATT = [];
LCON_UNATT = [];

for k = 1:length(S)
    SS = S;
    SS(k) = [];
%     g_att = zeros(60,(en-or)/1000*Fs+1,length(S));
%     g_unatt = zeros(60,(en-or)/1000*Fs+1,length(S));
%     Lcon_att = zeros(60,1);
%     Lcon_unatt = zeros(60,1);
    g_att = [];
    g_unatt = [];
    Lcon_att = [];
    Lcon_unatt = [];

    % FIRST, WE TRAIN THE DECODERS (FOR UNSHIFTED STIM/RESP)
    for j = 1:length(SS) % $$$$$$$$$$$$$$$$$$$$ CHOSE EITHER PARFOR OR FOR.
        addr = SS(j).code_no;
        tic
        start = round(EEG.event(addr).latency);
        fin = round(start + len_win_classified*EEG.srate);

        stimLeft = EEG.data(ch_left, start:fin)';
        stimRight = abs(hilbert(EEG.data(ch_right, start:fin)))';

        response = EEG.data(1:60, start:fin)';

        [wLeft,t, Lcon_L] = mTRFtrain(stimLeft, response, Fs, 1, or, en, LAMBDA);
        if strcmp (SS(j).type, 'left') == 1
            g_att = cat(3, g_att, wLeft);
%             g_att(:,:,j) = wLeft;
            Lcon_att = cat(2, Lcon_att, Lcon_L);
        else
            g_unatt = cat(3, g_unatt, wLeft);
%             g_unatt(:,:,j) = wLeft;
%             Lcon_unatt(:,j) = Lcon_L;
            Lcon_unatt = cat(2, Lcon_unatt, Lcon_L);
        end


        [wRight,t, Lcon_R] = mTRFtrain(stimRight, response, Fs, 1, or, en, LAMBDA);
        if strcmp (SS(j).type, 'right') == 1
            g_att = cat(3, g_att, wRight);
%             g_att(:,:,j) = wRight;
%             Lcon_att(:,j) = Lcon_R;
            Lcon_att = cat(2, Lcon_att, Lcon_R);
        else
            g_unatt = cat(3, g_unatt, wRight);
%             g_unatt(:,:,j) = wRight;
%             Lcon_unatt(:,j) = Lcon_R;
            Lcon_unatt = cat(2, Lcon_unatt, Lcon_R);
        end

        % report progress:
        elapsed_time = toc;
        disp(['Computing decoder from trial:' num2str(j)...
              ' Kernel length: ' num2str(en-or)...
              ' Elapsed: ' num2str(elapsed_time)...
              'k = ', num2str(k)])
    end

    % average the decoders over all the 30-second-long trials:
    g_att = mean(g_att,3);
    g_unatt = mean(g_unatt,3);
    
    Lcon_att = mean(Lcon_att,2);
    Lcon_unatt = mean(Lcon_unatt,2);
    
    G_ATT = cat(3, G_ATT, g_att);
    G_UNATT = cat(3, G_UNATT, g_unatt);
    LCON_ATT = cat(2, LCON_ATT, Lcon_att);
    LCON_UNATT = cat(2, LCON_UNATT, Lcon_unatt);

end

  
for j = 1:length(S) % FOR/PARFOR
    g_att = squeeze(G_ATT(:,:,j));
    g_unatt = squeeze(G_UNATT(:,:,j));
    Lcon_att = LCON_ATT(:,j);
    Lcon_att = LCON_UNATT(:,j);

    start = round(S(j).latency);
    fin = round(start + len_win_classified*EEG.srate);

   
    stimLeft = abs(hilbert(EEG.data(ch_left, start:fin)))';
    stimRight = abs(hilbert(EEG.data(ch_right, start:fin)))';
  

    response = EEG.data(1:60, start:fin)';


    [~, S(j).a_r_left, ~, S(j).a_MSE_left] = mTRFpredict(stimLeft, response, g_att, Fs, 1, or, en, Lcon_att);
    [~, S(j).a_r_right, ~, S(j).a_MSE_right] = mTRFpredict(stimRight, response, g_att, Fs, 1, or, en, Lcon_att);

    [~, S(j).u_r_left, ~, S(j).u_MSE_left] = mTRFpredict(stimLeft, response, g_unatt, Fs, 1, or, en, Lcon_unatt);
    [~, S(j).u_r_right, ~, S(j).u_MSE_right] = mTRFpredict(stimRight, response, g_unatt, Fs, 1, or, en, Lcon_unatt);
    disp(['parallel mode, trial ' num2str(j) ' DECODER ' num2str(j)])
end

for j = 1:length(S)
    if strcmp(S(j).type,'left') == 1
        S(j).a_correct = S(j).a_r_left > S(j).a_r_right;
        S(j).u_correct = S(j).u_r_left < S(j).u_r_right;
        
        S(j).a_r_att = S(j).a_r_left;
        S(j).a_r_unatt = S(j).a_r_right;
        S(j).u_r_att = S(j).u_r_left;
        S(j).u_r_unatt = S(j).u_r_right;
    end
    if strcmp(S(j).type,'right') == 1
        S(j).a_correct = S(j).a_r_left < S(j).a_r_right;
        S(j).u_correct = S(j).u_r_left > S(j).u_r_right;
        
        S(j).a_r_att = S(j).a_r_right;
        S(j).a_r_unatt = S(j).a_r_left;
        S(j).u_r_att = S(j).u_r_right;
        S(j).u_r_unatt = S(j).u_r_left;
    end
end

a_accuracy = mean([S(1:length(S)).a_correct])
u_accuracy = mean([S(1:length(S)).u_correct])