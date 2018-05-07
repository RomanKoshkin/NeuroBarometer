function [X_hat] = filt_EEG(X, Fs, stopband, passband, order)
    tic
    d = designfilt('lowpassfir', ...
        'PassbandFrequency', passband,...
        'StopbandFrequency', stopband,...
        'SampleRate', Fs, ...
        'FilterOrder', order);
    
    number_of_chans = size(X);
    number_of_chans = number_of_chans(1);
    
    X_hat = zeros(size(X));
    
    for chan = 1:number_of_chans
        disp(['Low-pass filtering EEG channel ' num2str(chan)...
            ' below ' num2str(passband) ' Hz'])
        X_hat (chan,:) = filtfilt(d,double(X(chan,:)));
    end
    
    disp('EEG filtering complete')
    toc
end