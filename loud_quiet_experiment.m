quiet = EEG.data; % epoched data
loud = EEG.data; % epoched data

TR = 49:53;
pick_divisor = 10;
picks_mq = randsample(1:length(quiet), round(length(quiet)/pick_divisor), false);
picks_ml = randsample(1:length(loud), round(length(loud)/pick_divisor), false);
mq = squeeze(mean(quiet(15,TR,picks_mq),2));
ml = squeeze(mean(loud(15,TR,picks_ml),2));


figure
subplot(1,2,1)
plot(EEG.times, mean(quiet(15,:,picks_mq),3));
hold on
plot(EEG.times, mean(loud(15,:,picks_ml),3));
hline(0); vline(0)
ax = gca;
ax.FontSize = 14;
ax.XLim = [-100 300];
leg = legend({'Session 1', 'Session 2'});
leg.FontSize = 14;

[h, p] = ttest2(ml, mq, 'Vartype', 'unequal');

hline(double([mean(mq) mean(ml)]), {'b', 'r'},...
    {'Mean N1 for loud bgrnd/quiet beeps', 'Mean N1 for quiet bgrnd/loud beeps'})


tit = title(...
    {['Target range: ', num2str([EEG.times(TR(1)) EEG.times(TR(end))])],...
    ['t-test: ', num2str(round(p, 2))],...
    ['Total trials in each session: ', num2str(length(picks_mq))]...
    });
tit.FontSize = 14;

subplot(1,2,2)
X = squeeze(mean(loud(:,:, picks_ml),3));
% [U,S,V] = svd(X);
% topoplot(U(:,1), EEG.chanlocs,'style','both','electrodes','labelpoint');
topoplot(X(:,51), EEG.chanlocs,'style','both','electrodes','labelpoint');
