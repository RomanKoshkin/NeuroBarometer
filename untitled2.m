elect_subj = {'Vovk', 'Indyukova', 'Buyanova', 'Deryabin', 'Kabanov', 'Kabanova', 'Sukhanova', 'Vishnyakova', 'Karpinskaya', 'Orlichenya'};
ads =       [3    14    15    19    23    24    25    30    39    47];
ch = 15;
t = -100:5:295;

N1 = zeros(length(elect_subj), length(ads));
scores = zeros(length(elect_subj), length(ads), 10);
displ = 30;
for i = 1:length(ads)
    for j = 1:length(elect_subj)
        c = c + 1;
        idx = find(ismember([EEG.event.code], ads(i)) & ismember({EEG.event.subj}, elect_subj(j)));
        [ERP, se, z] = plot_eq_subj(EEG, ads(i), elect_subj(j));
        ERPm = squeeze(mean(ERP(:,ch,:),1));
        [pks,locs] = findpeaks(-ERPm(displ+1:60));
        [~, max_loc] = max(pks);
        N1(j,i) = ERPm(locs(max_loc)+displ);
        scores(j,i,:) = mean(z,1);
    end
end