function [X_hat] = bandstopFIR(X, Fpass1, Fstop1, Fstop2, Fpass2, Fs)

    % Fpass1 = 100;
    % Fstop1 = 150;
    % Fstop2 = 350;
    % Fpass2 = 400;
    Apass1 = 0.5;
    Astop  = 65;
    Apass2 = 0.5;
    
    X_hat = zeros(size(X));
    
    d = designfilt('bandstopfir', ...
      'PassbandFrequency1',Fpass1,'StopbandFrequency1',Fstop1, ...
      'StopbandFrequency2',Fstop2,'PassbandFrequency2',Fpass2, ...
      'PassbandRipple1',Apass1,'StopbandAttenuation',Astop, ...
      'PassbandRipple2', Apass2, ...
      'DesignMethod','equiripple','SampleRate', Fs);

    fvtool(d)
    
    disp('bandstop filtering')
    for i = 1:size(X,1)
        X_hat(i,:) = filtfilt(d, X(i,:));
        disp(i)
    end
    disp('filtering complete') 
    
end