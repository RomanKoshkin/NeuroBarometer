% run this file AFTER you run stim_reconst_2.m
clear
load('EEG.mat')
load('output.mat') % stores a lot of things, including the two decoders.

Fs = EEG.srate;
T = 1/Fs;             % Sampling period       
L = size(g_att,2);    % Length of signal

for channel = 30:32
    X = g_att(channel,:)';
    Y = fft(X);

    P2 = abs(Y/L);
    P1 = P2(1:L/2+1);
    P1(2:end-1) = 2*P1(2:end-1);

    f = Fs*(0:(L/2))/L;
    subplot(2,1,1)
    plot(f,P1) 
    hold on
    title('Attended decoder')
 
    clear Y P2 P1 X f
    xlabel('f (Hz)')
    ylabel('|P1(f)|')
end
    
for channel = 30:32
    X = g_unatt(channel,:)';
    Y = fft(X);

    P2 = abs(Y/L);
    P1 = P2(1:L/2+1);
    P1(2:end-1) = 2*P1(2:end-1);

    f = Fs*(0:(L/2))/L;
    subplot(2,1,2)
    plot(f,P1) 
    hold on
    title('Unattended decoder')
 
    clear Y P2 P1 X f
    xlabel('f (Hz)')
    ylabel('|P1(f)|')
end
    
    
