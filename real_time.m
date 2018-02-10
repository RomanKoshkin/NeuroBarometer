% run this file AFTER you run stim_reconst_2.m
clear
load('EEG.mat')
load('output.mat') % stores a lot of things, including the two decoders.
%%

ch_left = find(ismember({EEG.chanlocs.labels}, 'Left_AUX') == 1);
ch_right = find(ismember({EEG.chanlocs.labels},'Right_AUX') == 1);
Fs = EEG.srate;

compute_envelope = 1;
Fs = EEG.srate

steps = round(1:Fs*1:length(EEG.data)-Fs*30);
parfor step_no = 1:length(steps)
    start = steps(step_no)
    fin = start + Fs*30;

    if compute_envelope == 1
        stimLeft = abs(hilbert(EEG.data(ch_left, start:fin)))';
        stimRight = abs(hilbert(EEG.data(ch_right, start:fin)))';
    else
        stimLeft = EEG.data(ch_left, start:fin)';
        stimRight = EEG.data(ch_right, start:fin)';
    end

    response = EEG.data(1:60, start:fin)';

    [recon, a_r_left(step_no), p, a_MSE_left(step_no)] = mTRFpredict(stimLeft, response, g_att, Fs, 1, or, en, Lcon);
    [recon, a_r_right(step_no), p, a_MSE_right(step_no)] = mTRFpredict(stimRight, response, g_att, Fs, 1, or, en, Lcon);

    [recon, u_r_left(step_no), p, u_MSE_left(step_no)] = mTRFpredict(stimLeft, response, g_unatt, Fs, 1, or, en, Lcon);
    [recon, u_r_right(step_no), p, u_MSE_right(step_no)] = mTRFpredict(stimRight, response, g_unatt, Fs, 1, or, en, Lcon);
    
    disp(step_no)
end
save('output2.mat', 'a_r_left', 'u_r_left', 'u_r_right', 'a_r_right')

%% computed correleations within sliding windows using the ATTENDED decoder:
load('output2.mat') 

figure; 
subplot(2,1,1)
Fs = EEG.srate;
plot(1:1269,a_r_left,1:1269, a_r_right, 'LineWidth', 0.5)
times = (round(1:Fs*1:length(EEG.data)-Fs*30)-1)/Fs;
ax = gca;
ax.XTick = linspace(0,length(times),10);
title('attended decoders')
ylabel('Correlation')
xlabel('Time, s')
for i = 5:4:61
    	on = EEG.event(i).latency/EEG.srate;
        off = EEG.event(i+1).latency/EEG.srate;

        x = [on off off on];
        y = [-0.2 -0.2 0.2 0.2];
        
        p = patch(x,y,'r');
        set(p,'FaceAlpha',0.15,'LineStyle','none');
end
for i = 7:4:63
    	on = EEG.event(i).latency/EEG.srate;
        off = EEG.event(i+1).latency/EEG.srate;

        x = [on off off on];
        y = [-0.2 -0.2 0.2 0.2];
        
        p = patch(x,y,'b');
        set(p,'FaceAlpha',0.15,'LineStyle','none');
end

% now the same, but using the UNattended decoders:
subplot(2,1,2)
Fs = EEG.srate;
plot(1:1269,u_r_left,1:1269, u_r_right, 'LineWidth', 0.5)
times = (round(1:Fs*1:length(EEG.data)-Fs*30)-1)/Fs;
ax = gca;
ax.XTick = linspace(0,length(times),10);
title('UNattended decoders')
ylabel('Correlation')
xlabel('Time, s')

for i = 5:4:61
    	on = EEG.event(i).latency/EEG.srate;
        off = EEG.event(i+1).latency/EEG.srate;

        x = [on off off on];
        y = [-0.2 -0.2 0.2 0.2];
        
        p = patch(x,y,'r');
        set(p,'FaceAlpha',0.15,'LineStyle','none');
end
for i = 7:4:63
    	on = EEG.event(i).latency/EEG.srate;
        off = EEG.event(i+1).latency/EEG.srate;

        x = [on off off on];
        y = [-0.2 -0.2 0.2 0.2];
        
        p = patch(x,y,'b');
        set(p,'FaceAlpha',0.15,'LineStyle','none');
end