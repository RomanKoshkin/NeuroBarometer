%% plot ERPs by subject with suppressed N1s
EEG = pop_loadset('filepath', '/Volumes/Transcend/10_ads/','filename', 'fourteen_subj_ica.set');

sigma = 0.028;
mu = 0.12;
fs = 200;
lo = -0.1;
hi = 0.3;
fs = 200;
gw = gausswin(fs, lo, hi, sigma, mu);
EEG_supp = supressERP(EEG, gw);

elect_subj = {...
    'Vovk', 'Indyukova', 'Buyanova', 'Deryabin', 'Kabanov', 'Kabanova',...
    'Sukhanova', 'Vishnyakova', 'Karpinskaya', 'Orlichenya','Pyzgareva'};
ads =       [0 3    14    15    19    23    24    25    30    39    47];
chan = 15;

t = -100:5:295;
c = 0;
figure;
for i = elect_subj
    c = c + 1;
    [ERP, se, z] = plot_eq_subj(EEG, ads, i);
    [ERP_supp, se, z] = plot_eq_subj(EEG_supp, ads, i);
    ERP_Fz = squeeze(mean(ERP(:,chan,:), 1));
    ERP_Fz_supp = squeeze(mean(ERP_supp(:,chan,:), 1));
    subplot(4,4,c)
    plot(t, ERP_Fz, t, ERP_Fz_supp), vline(0); hline(0)
    hold on
    plot(t, gw)
    xlim([-100 300])
    title(i)
end
