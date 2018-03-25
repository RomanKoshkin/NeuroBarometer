addpath('/Users/RomanKoshkin/Documents/MATLAB/Examples/PhysiologicSignalAnalysisExample')
fs = EEG.srate;
t = 100*fs:102*fs;
window_len = 64; % 100
noverlap = 50;
nfft = 512;

audio_left = double(EEG.data(1,t));
[S,F,T] = spectrogram(audio_left,window_len,noverlap,nfft,fs);
helperCWTTimeFreqPlot(S,T,F,'surf','STFT of data','Seconds','Hz')
%% extract freqs of interest:

class1 = find([EEG.event.type]==769);
class2 = find([EEG.event.type]==770);

class1_on = [EEG.event(class1).latency] + 125;
class2_on = [EEG.event(class2).latency] + 125;

data_c1 = zeros(length(class1_on),  3, 2*EEG.srate);
data_c2 = zeros(length(class2_on),  3, 2*EEG.srate);

STFT_c1 = zeros(length(class1_on), 31, 32, 3);
STFT_c2 = zeros(length(class2_on), 31, 32, 3);

for i = 1:length(class1_on)
    data_c1(i,:,:) = EEG.data(1:3, class1_on(i):class1_on(i)+2*EEG.srate-1);
    for j = 1:3
        [S,F,T] = spectrogram(squeeze(data_c1(i,j,:)),window_len,noverlap,nfft,fs);
        STFT_c1(i,:,:,j) = abs([S(13:28,:); imresize(S(36:63,:), [15, 32])]).^2;
    end
    disp(i)
end
for i = 1:length(class2_on)
    data_c2(i,:,:) = EEG.data(1:3, class2_on(i):class2_on(i)+2*EEG.srate-1);
    for j = 1:3
        [S,F,T] = spectrogram(squeeze(data_c2(i,j,:)),window_len,noverlap,nfft,fs);
        STFT_c2(i,:,:,j) = abs([S(13:28,:); imresize(S(36:63,:), [15, 32])]).^2;
    end
    disp(i)
end
X = cat(1, STFT_c1, STFT_c2);
Y = zeros(160,1);
Z = [repmat(0,80, 1); repmat(1,80,1)];
disp(size(X))

for i = 1:4
    subplot(2,2,i)
    imagesc(squeeze(X(80+i,:,:,3)))
end

save('/Users/RomanKoshkin/Downloads/BCI.mat', 'X', 'Y', 'Z')



%%
% cfs [frequencies x times (samples)]
% f [frequencies]
figure
[cfs,f] = cwt(double(EEG.data(30,:)),fs,'WaveletParameters',[14,400]);
cwt(audio_left,fs,'WaveletParameters',[14,50]);


x = double(EEG.data(16,200*Fs:230*Fs-1));
[WL,Freq,Ti] = spectrogram(x,Fs/2,Fs/2-1,119,Fs);
helperCWTTimeFreqPlot(WL,Ti,Freq,'surf','STFT of Quadratic Chirp','Seconds','Hz')