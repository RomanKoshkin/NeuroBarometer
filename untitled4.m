% GET DATA here:
% https://drive.google.com/open?id=144OPtEvZdfq4iwqEeh8Jpn9GTll7-8Jl

clc
clear
j = [150 250 450 650 750 950]; % lengths of the kernel, ms (approx)
figure;
for i = 1:length(j)
    load('speech_data.mat');
%     load('speech_data_2.mat');          % load the stim & response (EEG)
%     envelope = abs(hilbert(envelope));  % get the envelope
    
    % downsample to new target sampling freq:
    F_rs = 64; % 128 - WAY slower, minor accuracy boost 
    
    % downsample stim and resp:
    envelope = resample(envelope,F_rs,Fs); 
    EEG = resample(EEG,F_rs,Fs);
    % envelope = circshift(envelope, Fs*10,2);
    
    % get the window of interest (from 20 to 80 ms from the start)
    stimTrain = envelope(1:F_rs*60,1);
    respTrain = EEG(1:F_rs*60,:);
    
    % g - kernel (response function), t - times, con - ???
    [g,t,con] = mTRFtrain(stimTrain,respTrain,F_rs,1,0,j(i),1e5); %
    size(g,2)/F_rs
%     stimTest = envelope(F_rs*60+1:end,1);
%     respTest = EEG(F_rs*60+1:end,:);

    % the test data is the same is the training data. We test the
    % accuracy of the decoder on the training data:
    stimTest = stimTrain;
    respTest = respTrain;
    
    % recon - reconstructed stim, r - correlation btwin reconstructed and
    % original stim, p - p-values, MSE - error
    [recon,r(i),p,MSE] = mTRFpredict(stimTest,respTest,g,F_rs,1,0,j(i),con);
    
    % inspect kernels (average over all the channels):
    subplot(2,3,i)
    plot(t, mean(g,1));
    title(num2str(i))
    i
end

% plot correlation coefficients as a function of kernel lengths:
figure; plot(j, r, '-d')
a = gca;
a.XTick = j;
grid on