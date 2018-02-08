load('EEG.mat')
load('output.mat')
counter = 0;
Fs = EEG.srate
or = 0;    % kernel origin, ms
en = 500;
step_s = 1;

for start = round(1:Fs*step_s:length(EEG.data)-Fs*30)
    
    fin = start + Fs*30;

    if compute_envelope == 1
        stimLeft = abs(hilbert(EEG.data(ch_left, start:fin)))';
        stimRight = abs(hilbert(EEG.data(ch_right, start:fin)))';
    else
        stimLeft = EEG.data(ch_left, start:fin)';
        stimRight = EEG.data(ch_right, start:fin)';
    end

    response = EEG.data(1:60, start:fin)';

    counter = counter + 1;

    [recon, a_r_left(counter), p, a_MSE_left(counter)] = mTRFpredict(stimLeft, response, g_att, Fs, 1, or, en, Lcon);
    [recon, a_r_right(counter), p, S(counter).a_MSE_right(counter)] = mTRFpredict(stimRight, response, g_att, Fs, 1, or, en, Lcon);

    [recon, u_r_left(counter), p, u_MSE_left(counter)] = mTRFpredict(stimLeft, response, g_unatt, Fs, 1, or, en, Lcon);
    [recon, u_r_right(counter), p, u_MSE_right(counter)] = mTRFpredict(stimRight, response, g_unatt, Fs, 1, or, en, Lcon);
    
    disp(counter)
end

% computed correleations within sliding windows using the ATTENDED decoder:
figure; 
subplot(2,1,1)
Fs = EEG.srate;
plot(1:1269,a_r_left,1:1269, a_r_right, 'LineWidth', 0.5)
times = (round(1:Fs*1:length(EEG.data)-Fs*30)-1)/Fs;
ax = gca;
ax.XTick = linspace(0,length(times),10);

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