% EEG = pop_loadset('filepath', '/Volumes/Transcend/10_ads', 'filename', 'six_subj.set');
% EEG = pop_loadset('filepath', '/Volumes/Transcend/10_ads', 'filename', 'eight_subj.set');
EEG = pop_loadset('filepath', '/Volumes/Transcend/10_ads', 'filename', 'ten_subj_ica.set');
%%
c = 0;
t = -100:5:295;
figure
% ch = 15;
ch = [8, 15, 25, 14, 18, 17];
gb = {'bad', 'good', 'good', 'good', 'bad', 'mid', 'good', 'mid', 'bad', 'bad'};
for ad = [3    14    15    19    23    24    25    30    39    47]
    c = c + 1;
    [ERP, se] = plot_eq(EEG, ad); % here se is for the matrix ch x samples
    subplot(3, 4, c)
    erp = squeeze(mean(ERP(:,ch,:),2)); % ERP on the average channel
    se = std(erp,1)/sqrt(size(erp,1));  % SEM of each sample on the avg chan
    errorbar(t, mean(erp,1), se)
    tit = title([num2str(ad), gb(c)]); tit.FontSize = 14;
    ax = gca;
    ax.FontSize = 14;
    ax.YLim = [-1.5 1.5];
    ax.XLim = [-100 300];
    vline(0); hline(0); grid on
end

ad = [3    14    15    19    23    24    25    30    39    47];
[ERP, se] = plot_eq(EEG, ad);
subplot(3, 4, 12)
se = std(squeeze(mean(ERP(:,ch,:),2)),1)/sqrt(size(ERP,1));
errorbar(t, mean(squeeze(mean(ERP(:,ch,:),1)), 1), se)
tit = title('All ads'); tit.FontSize = 14;
ax = gca;
ax.FontSize = 14;
ax.YLim = [-1.5 1.5];
ax.XLim = [-100 300];
vline(0); hline(0); grid on

%% compare bad vs. good
ch = 17;
ad_bad = [3 23 39 47];
ad_good = [14 15 19 25];
[ERP_bad, se_bad] = plot_eq(EEG, ad_bad);
[ERP_good, se_good] = plot_eq(EEG, ad_good);

se_bad = std(squeeze(mean(ERP_bad(:,ch,:),2)),1)/sqrt(size(ERP_bad,1));
se_good = std(squeeze(mean(ERP_good(:,ch,:),2)),1)/sqrt(size(ERP_good,1));
errorbar(t, mean(squeeze(mean(ERP_bad(:,ch,:),1)), 1), se_bad); hold on
errorbar(t, mean(squeeze(mean(ERP_good(:,ch,:),1)), 1), se_good)
%% plot alpha by ad with error bars
% ch = [8, 15, 25, 14, 18, 17];
ch = 17;
ad = [3       14      15      19      23    24      25      30    39      47];
gb = {'bad', 'good', 'good', 'good', 'bad', 'mid', 'good', 'mid', 'bad', 'bad'};
c = 0;
alpha = [];


for i = ad
    c = c + 1;
    a_tmp = get_alpha_10(EEG, ch, i);
    a_tmp = mean(a_tmp,1);
    alpha_se(c) = std(a_tmp)/sqrt(length(a_tmp));
    alpha(c) = mean(a_tmp);
end

figure
subplot(1,2,1)
errorbar(1:10, alpha, alpha_se, 'ro')
ax = gca;
ax.XTick = 0:11;
ax.XLim = [0 11];
ax.XTickLabel = {'', ad, ''};
text(1:10, alpha, num2cell(round(sc(:,2)',2)),'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'right')
tit = title('Alpha power in the ads'); tit.FontSize = 14;
ax.XLabel.String = 'Ad numbers (10 ads)';

%% plot AW index by ad
lch = [7 8 12 14];
rch = [16 18 25 26];
ad = [3       14      15      19      23    24      25      30    39      47];
gb = {'bad', 'good', 'good', 'good', 'bad', 'mid', 'good', 'mid', 'bad', 'bad'};

ralpha = [];
lalpha = [];

c = 0;
for i = ad
    c = c + 1;
    r_tmp = get_alpha_10(EEG, rch, i);
    r_tmp = mean(r_tmp,1);
    ralpha_se(c) = std(r_tmp)/sqrt(length(r_tmp));
    ralpha(c) = mean(r_tmp);
end
c = 0
for i = ad
    c = c + 1;
    l_tmp = get_alpha_10(EEG, lch, i);
    l_tmp = mean(l_tmp,1);
    lalpha_se(c) = std(l_tmp)/sqrt(length(l_tmp));
    lalpha(c) = mean(l_tmp);
end

AW = ralpha-lalpha;

figure
subplot(1,2,1)
scatter(1:10, AW, 'ro')
ax = gca;
ax.XTick = 0:11;
ax.XLim = [0 11];
ax.XTickLabel = {'', ad, ''};
text(1:10, AW, num2cell(round(score,2)),'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'right')
tit = title('AW index (right alpha minus left alpha'); tit.FontSize = 14;
ax.XLabel.String = 'Ad numbers (10 ads)';
%%
ch = 17;
% ch = [8, 15, 25, 14, 18, 17];
ad = [3       14      15      19      23    24      25      30    39      47];
c = 0;
figure
for i = ad;
    c = c + 1;
    a_tmp = get_alpha_10(EEG, ch, i);
    subplot(3,4,c)
    plot(mean(a_tmp,1))
    tit = title({i, EEG.setname, length(a_tmp)}); tit.FontSize = 14;
end

%% get length of each ad

for i = 1:50
    x = find(ismember({EEG.event.type}, num2str(i)));
    mi = EEG.event(min(x)).latency;
    ma = EEG.event(max(x)).latency;
    len = (ma-mi)/EEG.srate;
    disp([num2str(i), '  ', num2str(len), '  ', num2str(length(x))])
end

for i = [3    14    15    19    23    24    25    30    39    47]
    x = find(ismember([EEG.event.code], i));
    mi = EEG.event(min(x)).latency;
    ma = EEG.event(max(x)).latency;
    len = (ma-mi)/EEG.srate;
    disp([num2str(i), '  ', num2str(len), '  ', num2str(length(x))])
end
%% get scores by question by ad number
load('scores_all.mat')
dat = dat_ten;
q = 'q2';
c = 0;
score = 0; se_sc = 0;
ad = unique([dat.ad_num]);
for i = ad
    c = c + 1;
    ad_idx = find(ismember([dat.ad_num], i));
    score(c) = mean([dat(ad_idx).(q)]);
    se_sc(c) = std([dat(ad_idx).(q)])/sqrt(length([dat(ad_idx).(q)]));
end

% figure
subplot(1,2,2)
errorbar(1:10, score, se_sc, 'ro')
ax = gca;
ax.XTick = 0:11;
ax.XLim = [0 11];
ax.YLim = [0 8];
ax.XTickLabel = {'', ad, ''};
text(1:10, score, num2cell(round(score,2)),'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'right')
tit = title('B'); tit.FontSize = 14;
ax.XLabel.String = 'Ad numbers (10 ads)';

da = da_fifty;

ad = [3    14    15    19    23    24    25    30    39    47];
c = 0;
score = 0; se_sc = 0;
for i = ad
    c = c + 1;
    ad_idx = find(ismember([da.ad_num], i));
    score(c) = mean([da(ad_idx).(q)]);
    se_sc(c) = std([da(ad_idx).(q)])/sqrt(length([da(ad_idx).(q)]));
end

subplot(1,2,1)
errorbar(1:10, score, se_sc, 'ro')
ax = gca;
ax.XTick = 0:11;
ax.XLim = [0 11];
ax.YLim = [0 8];
ax.XTickLabel = {'', ad, ''};
text(1:10, score, num2cell(round(score,2)),'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'right')
tit = title('A'); tit.FontSize = 14;
ax.XLabel.String = 'Ad numbers (50 ads)';

%% LR alpha
lch = [7 8 12 14];
rch = [16 18 25 26];

