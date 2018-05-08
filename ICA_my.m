% EEG1 = pop_select(EEG, 'time', [35 105]);

% load data:
load('/Users/RomanKoshkin/Downloads/EEG_latest/DAS_CH_AVG_500Hz.mat')

% cache and remove audio:
AUDIO = pop_select(EEG, 'channel', [64:65]);
EEG = pop_select(EEG, 'channel', [1:63]);

% filter
[EEG, ~, ~] = pop_eegfiltnew(EEG, 1, 48);

% resample:
EEG = pop_resample(EEG, 128);

% run ICA:
EEG = pop_runica(EEG, 'icatype', 'binica', 'extended', 1);
%EEG1 = pop_runica(EEG1, 'icatype', 'jader');
ICA = EEG;
ICA.data = ICA.icaact;
ICA.icaact = [];

pop_eegplot(ICA, 1, 0, 1);
pop_eegplot(EEG, 1, 0, 1);
pop_eegplot(AUDIO, 1, 0, 1);

figure; plot(EEG.data(13,EEG.srate*35:EEG.srate*39))
figure; plot(ICA.data(1,EEG.srate*35:EEG.srate*39))
%% 
% mixing matrix (mixes sources (ICs) into X (EEG measured at sensors). It
% back projects the signal in the estimated source space into the sensor
% space:

W_1 = inv(ICA.icaweights*ICA.icasphere);
W_1(:,1) = zeros(63,1);
backprojection = W_1*ICA.data;
% figure; plot(EEG.data(13,EEG.srate*35:EEG.srate*39)); hold on;plot(temp(13,EEG.srate*35:EEG.srate*39))
CLEAN_EEG = EEG; CLEAN_EEG.data = backprojection;
pop_eegplot(CLEAN_EEG, 1, 0, 1);
pop_eegplot(EEG, 1, 0, 1);

