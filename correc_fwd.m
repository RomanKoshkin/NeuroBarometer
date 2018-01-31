%% DECODE A WINDOW:

PLT_AESPA = 0;
channel = 'Fz';

S = struct('type', '?', 'r_left', 0, 'r_right', 0, 'correct', '?');
ch_left = find(ismember({EEG.chanlocs.labels}, 'Left_AUX') == 1);
ch_right = find(ismember({EEG.chanlocs.labels}, 'Right_AUX') == 1);
Fs = EEG.srate;
chan = find(ismember({EEG.chanlocs.labels}, channel) == 1);
for j = 3:67
    
    start = round(EEG.event(j).latency);
    fin = round(EEG.event(j+1).latency);
    

%     stimLeft = abs(hilbert(EEG.data(63, start*Fs:fin*Fs)))';
%     stimRight = abs(hilbert(EEG.data(64, start*Fs:fin*Fs)))';
%     response = EEG.data(1:61, start*Fs:fin*Fs)';
    
    stimLeft = abs(hilbert(EEG.data(ch_left, start:fin)))';
    stimRight = abs(hilbert(EEG.data(ch_right, start:fin)))';
    response = EEG.data(1:60, start:fin)';
    
    if PLT_AESPA == 1
        [wLeft,t, Lcon] = mTRFtrain(stimLeft, response, Fs, 0, -150, 450, 0.1);
        
        % plot(t, squeeze(wLeft)); legend({EEG.chanlocs.labels})
        [wRight,t] = mTRFtrain(stimRight, response, Fs, 0, -150, 450, 0.1);
        
        subplot(4,2,j-2)
        plot(t,squeeze(wLeft(1,:,chan)))
        hold on
        plot(t,squeeze(wRight(1,:,chan)))
        % xlim([-250,650])
        xlabel('Time lag (ms)'); ylabel('Amplitude (a.u.)')
        title (EEG.event(j).type)
    end
    
    [wLeft,t, Lcon] = mTRFtrain(stimLeft, response, Fs, 0, -200, 500, 0.5);
    [recon, r, p, MSE] = mTRFpredict(stimLeft, response, wLeft, Fs, 0, -200, 500, Lcon);
    S(j).type = EEG.event(j).type;
    S(j).r_left = r(chan);
    
    [wRight,t, Lcon] = mTRFtrain(stimRight, response, Fs, 0, -200, 500, 0.5);
    [recon, r , p, MSE] = mTRFpredict(stimRight, response, wRight, Fs, 0, -200, 500, Lcon);
    S(j).r_right = r(chan);
    j
    % if S(j).type == 'S  1' &
        
end

subplot(2,1,1)
plot([S(3:end).r_left]); hold on
plot([S(3:end).r_right])
SS1 = gca;
SS1.XTick = [1:65];
SS1.XTickLabel = {S(3:67).type};
title('FORWARD - RESPONSE RECONSTRUCTION')
grid on