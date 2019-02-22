%% plot ERPs on a given channel by subject
% ad = [3    14    15    19    23    24    25    30    39    47];
ad = [0];
ch = 15;
t = -100:5:295;
subjs = {'Deryabin', 'Kabanov', 'Kabanova', 'Ognevaya',...
        'Pyataeva', 'Rofe', 'Sukhanova', 'Vishnyakova', 'Karpinskaya', 'Orlichenya'};
figure
c = 0;
for subj = subjs
    c = c + 1;
    [ERP, se] = plot_eq_subj(EEG, ad, subj);
%     [ERP, se] = plot_eq(EEG, ad);
    subplot(3,4,c)
    plot(t, squeeze(mean(ERP(:,ch,:),1)))
   
    tit = title([subj, num2str(size(ERP,1))]); tit.FontSize = 14;
    ax = gca;
    ax.FontSize = 14;
%     ax.YLim = [-2.5 1.5];
    ax.XLim = [-100 300];
    vline(0); hline(0); grid on
end

%% plot P1 or N1 topographies by subject
t = -100:5:295;
P1_range = 22:40;
N1_range = 42:60;
subjs = {'Deryabin', 'Kabanov', 'Kabanova', 'Ognevaya',...
        'Pyataeva', 'Rofe', 'Sukhanova', 'Vishnyakova', 'Karpinskaya', 'Orlichenya' };
figure
c = 0;
for subj = subjs
    c = c + 1;
    [ERP, se] = plot_eq_subj(EEG, ad, subj);
    P1_topo = mean(mean(ERP(:,:,P1_range),3),1);
    subplot(3,4,c)
    topoplot(P1_topo, EEG.chanlocs,'style','both','electrodes','labelpoint');
    tit = title([subj, num2str(size(ERP,1))]); tit.FontSize = 14;
end

%%
subjs = {'Deryabin', 'Kabanov', 'Kabanova', 'Ognevaya', 'Pyataeva', 'Rofe', 'Sukhanova', 'Vishnyakova'};
ch = 17;

c = 0;
for i = subjs
    c = c + 1;
    x = find(ismember([EEG.event.code],3) & ismember({EEG.event.subj}, i));
    
end

