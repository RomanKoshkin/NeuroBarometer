elect_subj = {'Vovk', 'Indyukova', 'Buyanova', 'Deryabin', 'Kabanov', 'Kabanova',...
        'Sukhanova', 'Vishnyakova', 'Karpinskaya', 'Orlichenya','Pyzgareva'};
clc
displ = 30;
channel_of_interest = 'Fz';
quest = 2;
ads = [3    14    15    19    23    24    25    30    39    47];
t = -100:5:295;
n_perm = 300;

perm_p = zeros(length(ads), length(elect_subj));
N1 = zeros(length(reference_ads), length(elect_subj));
score = zeros(length(reference_ads), length(elect_subj));
ch = ismember({EEG.chanlocs.labels}, channel_of_interest);
for k = 1:length(ads)
    target_ad = ads(k);
    reference_ads = ads;
    reference_ads(k) = [];
    for j = 1:length(elect_subj)
            subj_id = subj_id + 1;
            for i = 1:length(reference_ads)           
                idx = find(ismember({EEG.event.subj}, elect_subj(j)) & ismember([EEG.event.code], reference_ads(i)));
                if isempty(idx)==1
                    continue
                end
                scores = mean(reshape([EEG.event(idx).score], 10, length(idx)), 2);
                [ERP, se, z] = plot_eq_subj(EEG, reference_ads(i), elect_subj(j));
                ERPm = squeeze(mean(ERP(:,ch,:),1));
                [pks,locs] = findpeaks(-ERPm(displ+1:60));
                [~, max_loc] = max(pks);
                N1(i,j) = ERPm(locs(max_loc)+displ);
                N1_t(i,j) = t(locs(max_loc)+displ);
                score(i,j) = scores(quest);
                disp(num2str([i, j, k]))
            end
            % remove outliers:
%             N1(N1<-4, j) = mean(N1(:,j)); 
            perm_p(k,j) = get_perm_p(N1(:,j), score(:,j), n_perm);
    end
end


function [p_perm] = get_perm_p(N1, score, n_perm)
    R = corrcoef(N1, score);
    R_true = R(2,1);
    R_perm = zeros(n_perm,1);
    for i = 1:n_perm
        idx = randsample(1:length(N1), length(N1), true);
        score_perm = score(idx);
        R = corrcoef(N1, score_perm);
        R_perm(i) = R(2,1);
    end
    p_perm = sum(abs(R_perm) > abs(R_true))/n_perm;
end