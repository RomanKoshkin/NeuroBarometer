function [l_filt, r_filt] = Filter (left, right, Fs, stopband, passband, order)

    d = designfilt('lowpassfir', ...
        'PassbandFrequency', passband,...
        'StopbandFrequency', stopband,...
        'SampleRate', Fs, ...
        'FilterOrder', order);
    
    disp('filtering the left channel')
    l_filt = filtfilt(d,double(left));
    disp('filtering the right channel')
    r_filt = filtfilt(d,double(right));
    disp('filtering complete')
end