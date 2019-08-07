%% you need to load a raw dataset (fs = 2000 Hz)

t0 = 17; % for Karpinskaya
t1 = 77; % for Karpinskaya
figure
t = t0*EEG.srate:t1*EEG.srate;
X = EEG.data(34,t);
plot(t, X)

%% find where the triggers SHOULD be
x = diff(X);
i = 0;
c = 0;
a = 0;
while i < length(x)
    i = i + 1;
    if x(i)>500
        c = c + 1;
        a(c) = i;
        i = i + 0.06*EEG.srate;
    end
end
a = a + t0*EEG.srate;
vline(a)
%% find actual trigger timings
[~, loc0] = min(abs([EEG.event.latency] - t0*EEG.srate));
[~, loc1] = min(abs([EEG.event.latency] - t1*EEG.srate));

actual_trig_latencies = [EEG.event(loc0:loc1).latency];
vline(actual_trig_latencies, 'green')
%% compute trigger timing mismatch distribution
mm = 0;
for i = 1:min(length(a), length(actual_trig_latencies))
    mm(i) =  (a(i) - actual_trig_latencies(i))/EEG.srate;
end
figure; histogram(mm, 10)
tit = title(EEG.comments); tit.FontSize = 14;