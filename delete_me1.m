%% correct trigger latencies
lb = 'one'; % two

% WE DON'T CORRECT JITTER FOR 'THREE', BECAUSE THE SAMPLING FREQUENCY
% COULDN'T CAPTURE A FREQUENCY HIGHER THAN HALF THE NYQUIST FREQUENCY
load([lb, '.mat']) % load the kernel
% figure; plot(x)
y = double(conv(EEG.data(34,:), x, 'same')); % convolve with the audio
% EEG.data(33,:) = y;

lats = find(ismember({EEG.event.type}, lb));
c = 0;
jitter = zeros(1, length(lats));
for i = lats
    c = c + 1;
    st = EEG.event(i).latency - 0.1*EEG.srate;
    en = EEG.event(i).latency + 0.15*EEG.srate;
    
    [pks, locs] = findpeaks(y(st:en), 'MinPeakDistance', 0.2*EEG.srate); 
%     plot(EEG.data(33,st:en));hold on;plot(EEG.data(34,st:en)*4000000); vline(EEG.event(i).latency - st)
    trig = st + locs - 0.025*EEG.srate;
%     vline(locs - 0.025*EEG.srate, 'green')
%     disp(EEG.event(i).latency/EEG.srate)
%     disp(trig/EEG.srate)
    jitter(c) = trig - EEG.event(i).latency;
    EEG.event(i).latency = trig;
end
histogram(jitter); title('Before correction')