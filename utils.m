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