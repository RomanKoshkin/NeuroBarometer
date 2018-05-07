function [X_hat] = notch50(X, Fs)
    
    X = double(X);
    X_hat = zeros(size(X));
    
    d = designfilt('bandstopiir',...
        'FilterOrder',2,...
        'HalfPowerFrequency1',49,...
        'HalfPowerFrequency2',51,...
        'DesignMethod','butter',...
        'SampleRate',Fs);

    fvtool(d)
    
    disp('notch filtering')
    for i = 1:size(X,1)
        X_hat(i,:) = filtfilt(d, X(i,:));
        disp(i)
    end
    disp('filtering complete') 
    
end