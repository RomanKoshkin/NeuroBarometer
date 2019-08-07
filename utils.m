%% recode ad numbers from string to numeric in the all.mat dataset
for i = 6891:length(EEG.event)
    if strcmp(EEG.event(i).type, 'A') ||...
       strcmp(EEG.event(i).type, 'Nachalo audio') ||...
       strcmp(EEG.event(i).type, 'Bip') ||...
       strcmp(EEG.event(i).type, 'a') ||...
       strcmp(EEG.event(i).type, 'boundary') ||...
       strcmp(EEG.event(i).type, 'empty')
   EEG.event(i).type = 0;
    else EEG.event(i).type = str2num(EEG.event(i).type);
    end
end
%%
for i = 2:966
    EEG.event(i).code = str2num(EEG.event(i).code);
end

%% plot topographies of P1/N1 components
N1_r = 46:56;
P1_r = 26:36;
[ERP, se] = plot_eq(EEG, ad);
x = squeeze(mean(ERP,1));
X = mean(x(:,N1_r),2);
figure
topoplot(X, EEG.chanlocs,'style','both','electrodes','labelpoint');
%% compute mean ISI
x = [EEG.event.latency]/EEG.srate;
x = diff(x);
x(x>2) = [];
mean(x)
%% plot ERPs by subj for 10 ads on the all.mat (50 ads there)
ad = [3    14    15    19    23    24    25    30    39    47];
data = unique({EEG.event.dataset})';
% data = {'2', '23'};
ch = 17;

c = 0;
figure
for i = 2:length(data)
    disp(data{i})
    c = c + 1;
    [ERP, se] = plot_eq_data(EEG, ad, data{i});
    subplot(3,4,c)
    plot(t, squeeze(mean(ERP(:,ch,:),1)))
    tit = title({data{i}, [num2str(size(ERP,1)) ' trials']}); tit.FontSize = 14;
    ax = gca; ax.YLim = [-1.5 1.5];ax.XLim = [-100 300];
    hline(0);vline(0)
end

%% to plot 0 againt all other ads:
figure
ch = 15;
ad = [0];
[ERP, se] = plot_eq(EEG, ad);
plot(t, squeeze(mean(ERP(:,ch,:),1)))
hold on

ad = [3    14    15    19    23    24    25    30    39    47];
[ERP, se] = plot_eq(EEG, ad);
plot(t, squeeze(mean(ERP(:,ch,:),1)))
hold on

hline(0);vline(0)

%% when you append datasets, run this:
for i = 1:length([EEG.event.latency])
    if isempty(EEG.event(i).code)==1
        EEG.event(i).code = -1;
    end
end

%% plot bad vs. good on a physical channel

ch = 15;
elect_subj = {'Deryabin', 'Kabanov', 'Kabanova', 'Sukhanova', 'Vishnyakova', 'Karpinskaya', 'Orlichenya'};

adbad = [3 24 39 47];
adgood = [14 15 19 25];


figure
subplot(1,2,1)
[ERP, se, z] = plot_eq_subj(EEG, adbad, elect_subj);
plot(t, squeeze(mean(ERP(:,ch,:),1))); hold on
[ERP, se] = plot_eq_subj(EEG, adgood, elect_subj);
plot(t, squeeze(mean(ERP(:,ch,:),1))); hold off;
grid on; hline(0);vline(0)
leg = legend({['BAD ads ', num2str(adbad)], ['GOOD ads ', num2str(adgood)]'}); leg.FontSize = 14;
tit = title({['Deryabin ', 'Kabanov ', 'Kabanova ', 'Sukhanova '], ['Vishnyakova ', 'Karpinskaya ', 'Orlichenya']}); tit.FontSize = 14;
%
load('scores_all.mat')
dat = dat_ten;

subplot(1,2,2)
errorbar(1:10, score, se_sc, 'ro')
ax = gca;
ax.XTick = 0:11;
ax.XLim = [0 11];
ax.YLim = [0 8];
ax.XTickLabel = {'', ad, ''};
text(1:10, score, num2cell(round(score,2)),'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'right')
tit = title('Score distributions by ads'); tit.FontSize = 14;
ax.XLabel.String = 'Ad numbers (10 ads)';
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
%% plot bad vs. good on a VIRTUAL CHANNEL (SPATIAL FILTERING)
ch = 17;
N1_rng = 36:46;
t = -100:5:295;
elect_subj = {'Deryabin', 'Kabanov', 'Kabanova', 'Sukhanova', 'Vishnyakova', 'Karpinskaya', 'Orlichenya'};
adbad = [3 24 39 47];
adgood = [14 15 19 25];

bads = zeros(length(elect_subj), 80);
goods = zeros(length(elect_subj), 80);

for i = 1:length(elect_subj)
    [ERP, se] = plot_eq_subj(EEG, 0, elect_subj(i));
    [U,S,V] = svd(squeeze(mean(ERP(:,:,N1_rng),1)));
%     subplot(3,4,i)
    if sign(U(ch,1)) < 0
        U = U * -1;
    end
%     topoplot(U(:,1), EEG.chanlocs,'style','both','electrodes','labelpoint');

%     [ERP, se] = plot_eq_subj(EEG, [adbad adgood], elect_subj(i));
    [ERP, se] = plot_eq_subj(EEG, adbad, elect_subj(i)); hold on;
    bads(i,:) = U(:,1)' * squeeze(mean(ERP,1));
%     plot(t, U(:,1)' * squeeze(mean(ERP,1)))
%     plot(t, squeeze(mean(ERP(:,ch,:),1)))
    [ERP, se] = plot_eq_subj(EEG, adgood, elect_subj(i));
    goods(i,:) = U(:,1)' * squeeze(mean(ERP,1));
    
%     plot(t, U(:,1)' * squeeze(mean(ERP,1)))
%     plot(t, squeeze(mean(ERP(:,ch,:),1)))
%     leg = legend({['BAD ads ', num2str(adbad)], ['GOOD ads ', num2str(adgood)]'}); leg.FontSize = 8;

%     leg = legend('Silent blocks'); leg.FontSize = 14;
    tit = title([elect_subj(i), 'Channel: Virtual']); tit.FontSize = 14;
%     tit = title([elect_subj(i), 'Channel: ', 'Cz']); tit.FontSize = 14;
    ax = gca; ax.XLim = [-100 300]; ax.YLim = [-2 2];
    grid on; hline(0);vline(0)
end

figure
plot(t, mean(bads,1)); hold on
plot(t, mean(goods,1))
leg = legend({['BAD ads ', num2str(adbad)], ['GOOD ads ', num2str(adgood)]'}); leg.FontSize = 8;
ax = gca; ax.XLim = [-100 300]; ax.YLim = [-2 2];
grid on; hline(0);vline(0)
tit = title([elect_subj, 'Channel: Virtual']); tit.FontSize = 14;