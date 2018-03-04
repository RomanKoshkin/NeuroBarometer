clear
load('KOS_DAS_80Hz_1.mat')
count = 0;

for iteration = 300:50:600
    clearvars -except EEG count iteration accu a_r_left a_r_right
    tic

    LAMBDA = 0.01;
    len_win_classified = 30;
    % shift_sec = [-2.75 -2.5 -2.25 -2 -1.75 -1.5 -1.25 -1 -0.75 -0.5 -0.25 0 0.25 0.5 0.75 1 1.25 1.5 1.75 2 2.25 2.5 2.75]; % vector of stimulus shifts
    % shift_sec = [-1.25 -1 -0.75 -0.5 -0.25 -0.125 0 0.125 0.25 0.5 0.75 1 1.25]; % vector of stimulus shifts
    % shift_sec = [-0.5 -0.25 -0.125 0 0.125 0.25 0.5]; % vector of stimulus shifts
    shift_sec = [0];

    compute_envelope = 1;
    % lags start and end:
    or = 0;    % kernel origin, ms %
    en = iteration;

    % range of events in the EEG.event struct
    % events = [5:64, 75:134, 143:202, 211:299, 308:396, 405:493]; % event ordinal numbers in the  
    % events = [5:64, 75:134, 143:202]; % event ordinal numbers in the  
    events = [75:134];
    % initialize an empty struct array to store results:
    S = struct('type', [], 'code_no', [], 'latency', [],...
        'a_r_left', [], 'a_r_right', [],...
        'a_correct', [], 'u_correct', [], ...
        'a_MSE_left', [], 'a_MSE_right', []);
    ch_left = find(ismember({EEG.chanlocs.labels}, 'Left_AUX') == 1);
    ch_right = find(ismember({EEG.chanlocs.labels},'Right_AUX') == 1);
    Fs = EEG.srate;

    % determine what's right, what's left:
    for j = events
        if strcmp(EEG.event(j).type, 'L_Lef_on') == 1 
            S(j).type = 'left';
            S(j).code_no = j;
        end
    %     if strcmp(EEG.event(j).type, 'L_Rig_on') == 1
    %         S(j).type = 'right';
    %         S(j).code_no = j;
    %     end

        if strcmp(EEG.event(j).type, 'other') == 1 ||...
           strcmp(EEG.event(j).type, 'L_Lef_off') == 1 ||...
           strcmp(EEG.event(j).type, 'L_Rig_off') == 1
            continue
        end
    end

    % get rid of empty rows:
    S = S(~cellfun('isempty',{S.code_no}));

    % Initialize vars for the parfor loop:
    Lcon = ones(size(EEG.data, 1)-2, 1); % minus audio channels

    % FIRST, WE TRAIN THE DECODERS (FOR UNSHIFTED STIM/RESP)
    counter = 0;
    parfor j = 1:length(S) % $$$$$$$$$$$$$$$$$$$$ CHOSE EITHER PARFOR OR FOR.
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

        g_right(:,:,j) = wRight;
        g_left(:,:,j) = wLeft;

        % report progress:
        elapsed_time = toc;
        disp(['Computing decoder from trial:' num2str(j) ' seconds'...
                    ' Kernel length: ' num2str(en-or)...
                    ' Elapsed: ' num2str(elapsed_time)...
                    ' Iteration ' num2str(iteration)])
    end


    % load onset latencies into S.latency:
    temp = num2cell([EEG.event([S.code_no]).latency]);
    [S.latency] = temp{:};

    % average the decoders over all the 30-second-long trials:
    % if we decode an unknown trial using g_left, then we should get a higher
    % correlation with the left channel (which means that it was a 'listen
    % left' trial), than with the right channel 

    g_left = mean(g_left,3);
    g_right = mean(g_right,3);


    for sh = 1:length(shift_sec)

        % now use the average decoders to predict what's what: 
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


            [~, S(j).a_r_left, ~, S(j).a_MSE_left] = mTRFpredict(stimLeft, response, g_left, Fs, 1, or, en, Lcon);
            [~, S(j).a_r_right, ~, S(j).a_MSE_right] = mTRFpredict(stimRight, response, g_right, Fs, 1, or, en, Lcon);

            disp(['parallel mode, trial ' num2str(j) ' Shift ' num2str(shift_sec(sh))])
        end

    end
    clc
    toc
    if strcmp(S(1).type, 'right')==1
        a_correl = mean([S.a_r_right]);
        u_correl = mean([S.a_r_left]);
        disp(['correlation with the attended channel (', S(1).type, ') is ' num2str(a_correl)])
        disp(['correlation with the unattended channel is ' num2str(u_correl)])
        [h,p] = ttest2([S.a_r_right],[S.a_r_left]);
        disp(['p-value = ' num2str(p)])
    else
        a_correl = mean([S.a_r_left]);
        u_correl = mean([S.a_r_right]);
        disp(['correlation with the attended channel (', S(1).type, ') is ' num2str(a_correl)])
        disp(['correlation with the unattended channel is ' num2str(u_correl)])
        [h,p] = ttest2([S.a_r_right],[S.a_r_left]);
        disp(['p-value = ' num2str(p)])
    end
    count = count + 1;
    accu(:, count) = int8([S.a_r_left]>[S.a_r_right])';
    a_r_left(:,count) = [S.a_r_left];
    a_r_right(:,count) = [S.a_r_right];
    p_val(count) = p;
end

a_r_left = mean(a_r_left,2);
a_r_right = mean(a_r_right,2);

rr = int8([a_r_left]>[a_r_right])';