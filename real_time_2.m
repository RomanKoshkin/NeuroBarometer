% run this file AFTER you run stim_reconst_2.m
clear
load('KOS_DAS_80Hz.mat')
%%
LAMBDA = 0.03;
compute_envelope = 1;
or = 0;    % kernel origin, ms
en = 50;   % kernel end, ms\

dataset_fraction = 1;

% events = [5:64, 75:134, 143:202]; % event ordinal numbers in the  
events = [5:64];

ch_left = find(ismember({EEG.chanlocs.labels}, 'Left_AUX') == 1);
ch_right = find(ismember({EEG.chanlocs.labels},'Right_AUX') == 1);
Fs = EEG.srate;

compute_envelope = 1;
Fs = EEG.srate;
win_len = 30;
step_size = 1;


%% determine what's right, what's left:

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


%% compute decoders, reconstructions and correlations:

no_of_steps = round(length(EEG.data)/EEG.srate/step_size);
starts = 1 : step_size*Fs : round(length(EEG.data))/dataset_fraction - win_len*Fs;


parfor step_no = 1:length(starts)                    % PARFOR ?
    start = starts(step_no);
    fin = start + Fs*win_len-1;

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
    
    Lcon = ones(size(EEG.data, 1)-2, 1); % minus audio channels
    
    [recon, a_r_left(step_no), p, a_MSE_left(step_no)] = mTRFpredict(stimLeft, response, wLeft, Fs, 1, or, en, Lcon);
    [recon, a_r_right(step_no), p, a_MSE_right(step_no)] = mTRFpredict(stimRight, response, wRight, Fs, 1, or, en, Lcon);
    
    disp(['Step ' num2str(step_no) ' out of ' num2str(no_of_steps)])
end
% plot(1:length(a_r_left),a_r_left,1:length(a_r_left), a_r_right)
% save('output2.mat', 'a_r_left', 'u_r_left', 'u_r_right', 'a_r_right')

%% computed correleations within sliding windows using the ATTENDED decoder:
% load('output2.mat') 

figure; 

times = round(starts/Fs);
plot(times,a_r_left,times, a_r_right, 'LineWidth', 0.5)

y = [-0.1 -0.1 0.9 0.9];
for i = 5:4:61
    	on = EEG.event(i).latency/EEG.srate;
        off = EEG.event(i+1).latency/EEG.srate;

        x = [on off off on];
                
        p = patch(x,y,'r');
        set(p,'FaceAlpha',0.15,'LineStyle','none');
end
for i = 7:4:63
    	on = EEG.event(i).latency/EEG.srate;
        off = EEG.event(i+1).latency/EEG.srate;

        x = [on off off on];
              
        p = patch(x,y,'b');
        set(p,'FaceAlpha',0.15,'LineStyle','none');
end
% ax = gca;
% ax.XTick = linspace(0, length(times),10);
% ax.XTickLabel = round(linspace(0, max(times),10));
% title('attended decoders')
% ylabel('Correlation')
% xlabel('Time, s')