% check if the sound is ok
% sound(EEG.data(61, 300*EEG.srate:305*EEG.srate), EEG.srate)

% if the sound is not ok, minmax normalize the audio:
% [EEG.data(61,:),~] = mapminmax(EEG.data(61,:),-1,1);
% [EEG.data(62,:),~] = mapminmax(EEG.data(62,:),-1,1);

left = double(EEG.data(61,:));
right = double(EEG.data(62,:));
l = left;
r = right;

% for testing:
% l = left(300*EEG.srate:320*EEG.srate);
% r = right(300*EEG.srate:320*EEG.srate);

env_l = envelope(l);
env_r = envelope(r);

% d = designfilt('bandpassfir', ...
%     'CutoffFrequency1', 2,...
%     'CutoffFrequency2', 8, ...
%     'SampleRate', 2000, ...
%     'FilterOrder', 1600);

d = designfilt('lowpassfir', ...
    'PassbandFrequency', 8,...
    'StopbandFrequency',8.5,...
    'SampleRate', 2000, ...
    'FilterOrder', 8000);
fvtool(d)
 
l_env_filt = filtfilt(d,env_l);
r_env_filt = filtfilt(d,env_r);

% to inspect audio:
% plot(env_l); hold on; plot(l_env_filt)
% figure
% plot(env_r); hold on; plot(r_env_filt)

% NOW FILTER THE DATASET THEN PUT THE PRE-PROCESSED AUDIO BACK
EEG.data(61,:) = l_env_filt;EEG.data(62,:) = r_env_filt;

% THEN DOWNSAMPLE:



