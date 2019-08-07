fs = 22000;
fc = 500;
fm = 40;
T = 1;
t = 0:1/fs:T;

x0 = sin(2*pi*fc*t);
xm = sin(2*pi*fm*t);
x = x0.*xm;
% x = xm;
figure;
subplot(1,2,1)
plot(t, x)
subplot(1,2,2)

window = 10000; % window size, samples
overlap = round(window*0.2); % overlap between adjacent window
nfft = 10000; % number of frequencies to compute in each window
spectrogram(x, blackman(window), overlap, nfft, fs, 'power');
colorbar('off')

%%
Y = fft(ammod(xm, 500, fs));
L = length(Y)
P2 = abs(Y/L);
P1 = P2(1:L/2+1);
P1(2:end-1) = 2*P1(2:end-1);
f = fs*(0:(L/2))/L;
plot(f,P1) 
title('Single-Sided Amplitude Spectrum of X(t)')
xlabel('f (Hz)')
ylabel('|P1(f)|')