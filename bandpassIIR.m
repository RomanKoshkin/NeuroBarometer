function [X_hat] = bandpassIIR(X, Fs, passband, stopband, order)
    X_hat = zeros(size(X));

    d = designfilt('bandpassiir',...
        'FilterOrder',order,...
         'HalfPowerFrequency1',passband,...
         'HalfPowerFrequency2',stopband,...
         'SampleRate',Fs);

    fvtool(d)

    disp('lowpass filtering')
    for i = 1:size(X,1)
        X_hat(i,:) = filtfilt(d,double(X(i,:)));
        disp(i)
    end
    disp('lowpass filtering complete')

end


