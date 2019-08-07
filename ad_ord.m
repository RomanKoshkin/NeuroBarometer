%% plot ten ERP curves (one for each ad) not by type but by their ORDINAL NUMBER
% depends on plot_e_ord.m
ch = 17;
t = -100:5:295;

subj = {'Deryabin', 'Kabanov', 'Kabanova', 'Ognevaya',...
        'Pyataeva', 'Rofe', 'Sukhanova', 'Vishnyakova', 'Karpinskaya', 'Orlichenya'};
    
subj = {'Deryabin', 'Kabanov', 'Kabanova', 'Sukhanova', 'Vishnyakova', 'Karpinskaya', 'Orlichenya'};
figure
for ad_ord = 0:10
    [ERP, se] = plot_e_ord(EEG, ad_ord, subj);
    subplot(3,4,ad_ord+1)
    plot(t, squeeze(mean(ERP(:,ch,:))))
    ax = gca; ax.FontSize = 14;
    ax.YLim = [-1 1];ax.XLim = [-100 300];
    hline(0);vline(0)
    tit = title(ad_ord); tit.FontSize = 14;
end