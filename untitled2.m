t = 0:1e-4:1;
x = [1+cos(2*pi*50*t)].*cos(2*pi*1000*t);

plot(t,x)
xlim([0 0.1])
xlabel('Seconds')

y = hilbert(x);
env = abs(y);

plot(t,x)
hold on
plot(t,[-1;1]*env,'r','LineWidth',2)
xlim([0 0.1])
xlabel('Seconds')
%% Hilbert transform:

start = 21;
fin = 22;
Fs = 200;
t = 1:1+Fs;
x = EEG.data(63,start*Fs:fin*Fs);
plot(t, x)
hold on
env = abs(hilbert(x));
plot(t, [-1;1]*env,'r','LineWidth',2)


% read in the AUX chan and save it as audio:
x = EEG.data(62,:)/1000000;
audiowrite('stim_from_EEG.wav', x, 2000);

%% Now sychronize this mess in AUDACITY:

%% 
% read in the synced audio:
x = audioread('stim_from_EEG_synced.wav');

% plot the channels:
subplot(211);plot(x(30000:40000,1));hold on
title ('left')
subplot(212);plot(x(30000:40000,2))
title ('right')

% copy the left audio channel into EEG.data matrix as channel 63:
EEG.data(63,1:length(x)) = x(:,1);
% copy the right audio channel into EEG.data matrix as channel 64:
EEG.data(64,1:length(x)) = x(:,2);

EEG.data(63,1:length(x)) = x(:,1);

% EEG.chanlocs = chnlcs;
%% play a 5 s interval of the "good" audio:
sound(EEG.data(63:64,40000:50000),2000)

%% play a 5 s interval of the AUX chan:
sound(EEG.data(63:64,40000:50000),2000)

%
load('speech_data.mat');
envelope1 = resample(envelope,64,128);
EEG1 = resample(EEG,64,128);
stimTrain = envelope1(1:64*60,1);
respTrain = EEG1(1:64*60,:);
[g,t,con] = mTRFtrain(stimTrain,respTrain,64,1,0,500,1e5);
stimTest = envelope(64*60+1:end,1);
respTest = EEG1(64*60+1:end,:);
[recon,r,p,MSE] = mTRFpredict(stimTest,respTest,g,64,1,0,500,con);


%%
clc
clear
j = [150 250 450 650 750 950];
figure;
for i = 1:length(j)
%    load('speech_data.mat');
    load('speech_data_2.mat');
    envelope = abs(hilbert(envelope));
    F_rs = 64; % 128 - WAY slower, minor accuracy boost
    
    envelope = resample(envelope,F_rs,Fs);
    EEG = resample(EEG,F_rs,Fs);
    stimTrain = envelope(20:F_rs*80,1);
    respTrain = EEG(20:F_rs*80,:);
    [g,t,con] = mTRFtrain(stimTrain,respTrain,F_rs,1,0,j(i),1e5); %
%     stimTest = envelope(F_rs*60+1:end,1);
%     respTest = EEG(F_rs*60+1:end,:);
    stimTest = stimTrain;
    respTest = respTrain;
    [recon,r(i),p,MSE] = mTRFpredict(stimTest,respTest,g,F_rs,1,0,j(i),con);
    subplot(2,3,i)
    plot(t, mean(g,1));
    title(num2str(i))
    i
end
figure; plot(j, r, '-d')
a = gca;
a.XTick = j;
grid on

%%
stimTest = stimTrain;
respTest = respTrain;
[recon,r,p,MSE] = mTRFpredict(stimTest,respTest,g,64,1,0,500,con);

