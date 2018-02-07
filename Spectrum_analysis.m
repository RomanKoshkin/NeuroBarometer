
% get audio from the EEG dataset:
x = EEG.data(61:62,:);

% first remove the DC offset in the audio:
x(1,:) = x(1,:) - mean(x(1,:));
x(2,:) = x(2,:) - mean(x(2,:));


figure
win_s = 200:600;
times = win_s*EEG.srate;
plot(x(1,min(times):max(times)),'Color', 'r')

hold on
% x_hil = abs(hilbert(x(1,:)));
% x_hil = envelope(x, 500);
% plot(x_hil(1, min(times):max(times)), 'LineWidth', 3)

%%
% EEG.data(61:62,:) = x_hil;


%% see the spectrum:
Fs = EEG.srate;            % Sampling frequency                    
T = 1/Fs;             % Sampling period       
L = length(x);        % Length of signal
t = (0:L-1)*T;        % Time vector

Y = fft(x(1,:));
P2 = abs(Y/L);
P1 = P2(1:L/2+1);
P1(2:end-1) = 2*P1(2:end-1);
f = Fs*(0:(L/2))/L;

figure
subplot(2,1,1)
plot(f,P1) 
title('Single-Sided Amplitude Spectrum of X(t)')
xlabel('f (Hz)')
ylabel('|P1(f)|')


tic
subplot(2,1,2)
window = 8000; % window size, samples
overlap = round(window*0.95); % overlap between adjacent window
nfft = 512*8; % number of frequencies to compute in each window
spectrogram(x(1,min(times):max(times)), blackman(window), overlap, nfft, Fs, 'power');
colorbar('off')
title('Power vs. Time, six minutes of the left channel')
toc
