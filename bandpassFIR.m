function [X_hat] = bandpassFIR(X, Fs, passband, stopband, order, Fstop, Fpass, verbose)
X_hat = zeros(size(X));

d = designfilt('lowpassfir', ...
    'PassbandFrequency', passband,...
    'StopbandFrequency', stopband,...
    'SampleRate', Fs, ...
    'FilterOrder', order);
if verbose==1
    fvtool(d)
end

disp('lowpass filtering')
for i = 1:size(X,1)
    X_hat(i,:) = filtfilt(d,double(X(i,:)));
    disp(i)
end
disp('lowpass filtering complete')


% Fstop = 30;
% Fpass = 35;
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
for i = 1:size(X_hat,1)
    X_hat(i,:) = filtfilt(d, X_hat(i,:));
    disp(i)
end
disp('filtering complete') 


end


