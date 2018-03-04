addpath('/Users/RomanKoshkin/Documents/MATLAB/Examples/PhysiologicSignalAnalysisExample')
fs = EEG.srate;
t = 300*fs:310*fs;
audio_left = double(EEG.data(61,t));
[S,F,T] = spectrogram(audio_left,100,98,128,fs);
helperCWTTimeFreqPlot(S,T,F,'surf','STFT of Quadratic Chirp','Seconds','Hz')

% cfs [frequencies x times (samples)]
% f [frequencies]
figure
[cfs,f] = cwt(audio_left,fs,'WaveletParameters',[14,400]);
cwt(audio_left,fs,'WaveletParameters',[14,50]);
