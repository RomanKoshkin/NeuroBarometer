a = [];
for i = 1:50
    idx = find(ismember({EEG.event.type},num2str(i)));
    a = cat(2,a, idx);
end

ISIs = diff([EEG.event(a).latency]/EEG.srate);
histogram(ISIs)

%%
theta = 0.05;
figure

subplot(2,2,1)
k = 1;
x = gamrnd(k, theta, [10000,1]);
histogram(x, 'Normalization', 'probability')
title(sprintf('M=%2f', mean(x)))

subplot(2,2,2)
k = 2;
x = gamrnd(k, theta, [10000,1]);
histogram(x, 'Normalization', 'probability')
title(sprintf('M=%2f', mean(x)))

subplot(2,2,3)
k = 3;
x = gamrnd(k, theta, [10000,1]);
histogram(x, 'Normalization', 'probability')
title(sprintf('M=%2f', mean(x)))

subplot(2,2,4)
k = 6;
x = gamrnd(k, theta, [10000,1]);
histogram(x, 'Normalization', 'probability')
title(sprintf('M=%2f', mean(x)))