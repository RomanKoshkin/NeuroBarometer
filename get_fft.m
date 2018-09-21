function [f, P1] = get_fft(channel, start, fin)
    
    global EEG
%     channel = 17;
%     start = 200*EEG.srate;
%     fin = 202*EEG.srate;

    %%
    Fs = EEG.srate;            % Sampling frequency                    
    x = EEG.data(channel, start:fin);
    x = x - mean(x);
    T = 1/Fs;             % Sampling period       
    L = length(x);        % Length of signal
    t = (0:L-1)*T;        % Time vector

    Y = fft(x);
    P2 = abs(Y/L);
    P1 = P2(1:floor(L/2+1));
    P1(2:end-1) = 2*P1(2:end-1);
    f = Fs*(0:(L/2))/L;
%     plot(f,P1)
end