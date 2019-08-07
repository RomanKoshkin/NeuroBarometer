% cd /Users/RomanKoshkin/Documents/MATLAB/NeuroBarometer
% eeglab redraw
% EEG = pop_loadset('filepath', '/Volumes/Transcend/10_ads/','filename', 'fourteen_subj_ica.set');
%%
% displ = 30;
% channel_of_interest = 'Fz';
% t = -100:5:295;
% ads = [3    14    15    19    23    24    25    30    39    47];
% ch = ismember({EEG.chanlocs.labels}, channel_of_interest);
% elect_subj = {'Vovk', 'Indyukova', 'Buyanova', 'Deryabin', 'Kabanov', 'Kabanova',...
%     'Sukhanova', 'Vishnyakova', 'Karpinskaya', 'Orlichenya','Pyzgareva'};
% quest = 4;
% score = zeros(length(ads)*length(elect_subj),1);
% N1 = zeros(length(ads)*length(elect_subj),1);
% N1_t = zeros(length(ads)*length(elect_subj),1);
% 
% c = 0;
% for j = 1:length(elect_subj)
%     for i = 1:length(ads)
%         c = c + 1;
%         idx = find(ismember({EEG.event.subj}, elect_subj(j)) & ismember([EEG.event.code], ads(i)));
%         if isempty(idx)==1
%             continue
%         end
%         scores = mean(reshape([EEG.event(idx).score], 10, length(idx)), 2);
%         [ERP, se, z] = plot_eq_subj(EEG, ads(i), elect_subj(j));
%         ERPm = squeeze(mean(ERP(:,ch,:),1));
%         [pks,locs] = findpeaks(-ERPm(displ+1:60));
%         [~, max_loc] = max(pks);
%         N1(c) = ERPm(locs(max_loc)+displ);
%         N1_t(c) = t(locs(max_loc)+displ);
%         score(c) = scores(quest);
% 
%     %     subplot(2,5,i)
%     %     plot(t,ERPm)
%     %     vline(N1_t(i))
%     %     title([char(channel_of_interest), ' ', num2str(ads(i)), ' ', num2str(score(i))])
%     end
% end
% % correct outliers:
% N1(N1<-4) = mean(N1);
% 
% figure
% scatter(N1, score)
% xlabel('N1 amplitude')
% ylabel('score')
% hold on
% 
% X = [N1 ones(length(N1),1)];
% y_true = score;
% beta = X'*X \ X'*y_true;
% ax = gca;
% x = linspace(ax.XLim(1), ax.XLim(2), 10);
% y = beta(1)*x + beta(2);
% plot(x,y)

%% suppose we have a target ad and try to predict its score based on the ratings of reference ads:
clc
displ = 30;
channel_of_interest = 'Fz';
quest = 2;
n_permutations = 200;
ads = [3    14    15    19    23    24    25    30    39    47];
t = -100:5:295;
n_perm = 300;
whiten = 1;
opt = 2;


for k = 1:length(ads)
    target_ad = ads(k);
    figure
    reference_ads = ads;
    reference_ads(k) = [];
    labels = sprintfc('%d', reference_ads);
    ch = ismember({EEG.chanlocs.labels}, channel_of_interest);
%     elect_subj = {'Vovk', 'Indyukova', 'Buyanova', 'Deryabin', 'Kabanov', 'Kabanova',...
%         'Sukhanova', 'Vishnyakova', 'Karpinskaya', 'Orlichenya','Pyzgareva'};

    elect_subj = {'Sukhanova'};
    
    PERM_P = zeros(length(reference_ads),length(elect_subj));
    
    score = zeros(length(reference_ads)*length(elect_subj),1);
    N1 = zeros(length(reference_ads)*length(elect_subj),1);
    N1_t = zeros(length(reference_ads)*length(elect_subj),1);

    c = 0;
    subj_id = 0;
    subj_color = [[0 0 1];[1 0 1];[0.5 0 1]; [0 1 1];[1 0 0];[0 1 0]; [1 1 0]; [0.5 0.5 0.5]; [0 0 0]; [1 0.5 0]; [0.5 1 0]];
    
    subj_color_vec = zeros(length(elect_subj) * length(reference_ads), 3);
    for j = 1:length(elect_subj)
        subj_id = subj_id + 1;
        for i = 1:length(reference_ads)           
            c = c + 1;
            subj_color_vec(c,:) = subj_color(subj_id,:);
            idx = find(ismember({EEG.event.subj}, elect_subj(j)) & ismember([EEG.event.code], reference_ads(i)));
            if isempty(idx)==1
                continue
            end
            scores = mean(reshape([EEG.event(idx).score], 10, length(idx)), 2);
            [ERP, se, z] = plot_eq_subj(EEG, reference_ads(i), elect_subj(j));
            if whiten==1
                [ERP] = whiten_last_100(ERP, opt);
            end
            ERPm = squeeze(mean(ERP(:,ch,:),1));
            [pks,locs] = findpeaks(-ERPm(displ+1:60));
            [~, max_loc] = max(pks);
            N1(c) = ERPm(locs(max_loc)+displ);
            N1_t(c) = t(locs(max_loc)+displ);
            score(c) = scores(quest);
        end
    end
    % remove outliers:
    N1(N1<-4) = mean(N1);
    
    disp(length(N1))
    perm_p = get_perm_p(N1, score, n_perm);
    PERM_P(k,j) = perm_p;
%     subplot(1,2,k)
    disp(['Processing target ad: ', num2str(k)])
    
    if length(elect_subj)==1
        plot(N1, score, 'rx')
        text(N1, score, labels, 'VerticalAlignment', 'bottom')
    else
        scatter(N1, score, 30, subj_color_vec)
    end
    xlabel('N1 amplitude')
    ylabel('score')
    xlim([-3.5 0.5]);
    ylim([-1 11]);
    hold on

    X = [N1 ones(length(N1),1)];
    y_true = score;
    beta = X'*X \ X'*y_true;
    disp(beta')
    ax = gca;
    x = linspace(ax.XLim(1), ax.XLim(2), 10);
    y = beta(1)*x + beta(2);
    plot(x,y)
    title(['Target ad: ', num2str(target_ad), ', Question: ', num2str(quest), ', p-val: ', num2str(perm_p)])

    idx = find(ismember({EEG.event.subj}, elect_subj) & ismember([EEG.event.code], target_ad));
    scores = mean(reshape([EEG.event(idx).score], 10, length(idx)), 2);

    [ERP, se, z] = plot_eq_subj(EEG, target_ad, elect_subj);
    if whiten==1
        [ERP] = whiten_last_100(ERP, opt);
    end
    ERPm = squeeze(mean(ERP(:,ch,:),1));
    [pks,locs] = findpeaks(-ERPm(displ+1:60));
    [~, max_loc] = max(pks);
    N1_target = ERPm(locs(max_loc)+displ);
    N1_t_target = t(locs(max_loc)+displ);
    score_target = scores(quest);

    vline(N1_target, 'green', 'measured N1 for target ad', 90)
    score_pred = beta(1)*N1_target + beta(2);
    hline(score_pred, 'red', 'pred score for target ad')
    hline(score_target, 'blue', 'true score for target ad')

    ax = gca;
    ax.FontSize = 14;
    CI = get_boot_CI(N1_target, N1, score, n_permutations);
    hline(CI(1))
    hline(CI(2))
    ax = gca;
end

function [CI] = get_boot_CI(N1_target, N1, score, n_permutations)
    score_target_perm = zeros(n_permutations, 1);
    for i = 1:n_permutations
        idx = randsample([1:length(N1)], length(N1), true);
        N1_perm = [N1(idx), ones(length(N1),1)];
        score_perm = score(idx);
        coeff = N1_perm'*N1_perm \ N1_perm'*score_perm;
        score_target_perm(i) = N1_target * coeff(1) + coeff(2); % y = kx + b
    end
    CI = quantile(score_target_perm, [0.025, 0.975]);
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

function [ERP] = whiten_last_100(ERP, opt)
%     get whitening matrix:
    X = ERP(:,:,61:80);
    tr = size(X,1);
    if opt==1
        c = zeros(tr,32,32);
        for i = 1:tr
            c(i,:,:) = cov(squeeze(X(i,:,:))');
        end
        C = squeeze(mean(c,1));
    end
    
    if opt==2
        X = ERP(:,:,61:80);
        X = permute(X, [2,3,1]);
        X = reshape(X,32,[]);
        C = cov(X');
    end
    
    for i = 1:tr
        W = inv(sqrtm(C));
        ERP(i,:,:) = W * squeeze(ERP(i,:,:));
    end        
end