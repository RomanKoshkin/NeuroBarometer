function [X_hat] = highpassFIR(X, Fs, Fstop, Fpass, verbose)

X = double(X);


% Fstop = 1;
% Fpass = 3;
% Fs = 2000;
Astop = 65;
Apass = 0.5;


d = designfilt('highpassfir',...
    'StopbandFrequency',Fstop,...
    'PassbandFrequency',Fpass,...
    'StopbandAttenuation',Astop,...
    'PassbandRipple',Apass,...
    'SampleRate',Fs,...
    'DesignMethod','equiripple');
if verbose == 1
    fvtool(d)
end
disp('highpass filtering')
for i = 1:size(X,1)
    X_hat(i,:) = filtfilt(d, X(i,:));
    disp(i)
end
disp('filtering complete') 


end


