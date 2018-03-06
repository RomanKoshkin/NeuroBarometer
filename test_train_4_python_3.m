clear
load('BIG.mat')

filter_audio = 1;
        stopband = 8.5;
        passband = 8;
        order = 1000;
compute_envelope = 1;

trial_len = 30; % what's the duration of a trial
winsize = 5; % size of window
stepsize = 1; % step between windows (onset-to-onset)

% range of events in the EEG.event struct
events = [5:64, 75:134, 143:202, 211:299, 308:396, 405:493]; % event ordinal numbers in the  
% events = [5:64]; % event ordinal numbers in the  
% events = [5:64, 75:134, 143:202];

% initialize an empty struct array to store results:
S = struct('type', [], 'code_no', [], 'latency', [],...
    'a_r_right', [], 'u_r_left', [],...
    'a_r_left', [], 'u_r_right', []);
ch_left = find(ismember({EEG.chanlocs.labels}, 'Left_AUX') == 1);
ch_right = find(ismember({EEG.chanlocs.labels},'Right_AUX') == 1);
Fs = EEG.srate;

if filter_audio == 1
    [l, r] = filt_audio(EEG.data(ch_left,:), EEG.data(ch_right,:), Fs, stopband, passband, order);
    figure; plot(EEG.data(61,1000:1300));hold on;plot(l(1000:1300))
    EEG.data(ch_left,:) = l;
    EEG.data(ch_right,:) = r;
    
end
  
% minmax normalize:
% EEG.data(ch_left,:) = mapminmax(EEG.data(ch_left,:),-1,1);
% EEG.data(ch_right,:) = mapminmax(EEG.data(ch_right,:),-1,1);

if compute_envelope == 1
    figure; plot(EEG.data(61,1000:1300), 'LineWidth', 1); hold on
%     EEG.data(ch_left,:) = abs(hilbert(EEG.data(ch_left,:)));
%     EEG.data(ch_right,:) = abs(hilbert(EEG.data(ch_right,:)));
    EEG.data(ch_left,:) = envelope(EEG.data(ch_left,:));
    EEG.data(ch_right,:) = envelope(EEG.data(ch_right,:));
    plot(EEG.data(61,1000:1300), 'LineWidth', 3)
end

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

    if strcmp(EEG.event(j).type, 'other') == 1 ||...
       strcmp(EEG.event(j).type, 'L_Lef_off') == 1 ||...
       strcmp(EEG.event(j).type, 'L_Rig_off') == 1
        continue
    end
end

% get rid of empty rows:
S = S(~cellfun('isempty',{S.code_no}));

% load onset latencies into S.latency:
temp = num2cell([EEG.event([S.code_no]).latency]);
[S.latency] = temp{:};

% data split:
counter = 0;
for i = 1:length({S.type})
    start = round(S(i).latency);
    fin = start + winsize*Fs-1;
    disp([num2str(start/Fs) '___' num2str((S(i).latency + 30*Fs)/Fs)])
    disp([num2str(fin/Fs) '___' num2str((S(i).latency + 30*Fs)/Fs)])

    while fin < S(i).latency + trial_len*Fs
        counter = counter + 1;
        X(counter,:,:) = EEG.data(1:60,start:fin);
        if strcmp(S(i).type, 'right') == 1
            Y(counter,:) = EEG.data(62,start:fin);
            Z(counter) = 1;
            disp([num2str(counter) '_' S(i).type ' right, trial = ', num2str(i)])
        else
            Y(counter,:) = EEG.data(61,start:fin);
            Z(counter) = 0;
            disp([num2str(counter) '_' S(i).type ' left, trial = ', num2str(i)])
        end
        start = start + stepsize*Fs - 1;
        disp([num2str(start/Fs) '___' num2str((S(i).latency + trial_len*Fs)/Fs)])
        fin = start + winsize*Fs - 1;    
        disp([num2str(fin/Fs) '___' num2str((S(i).latency + trial_len*Fs)/Fs)])
    end
end
save('EEG_big4CNN.mat', 'X', 'Y', 'Z')