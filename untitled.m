clc
displ = 30;
channel_of_interest = 'Fz';
quest = 2;
ads = [3    14    15    19    23    24    25    30    39    47];
t = -100:5:295;

ch = ismember({EEG.chanlocs.labels}, channel_of_interest);

subj = {'Vovk', 'Indyukova', 'Buyanova', 'Deryabin', 'Kabanov', 'Kabanova',...
    'Sukhanova', 'Vishnyakova', 'Karpinskaya', 'Orlichenya','Pyzgareva'};

ERPs = zeros(length(subj), 80);
figure
for j = 1:length(subj)
%     figure
    for i = 1:length(ads)           
        idx = find(ismember({EEG.event.subj}, subj(j)) & ismember([EEG.event.code], ads(i)));
        if isempty(idx)==1
            continue
        end
        scores = mean(reshape([EEG.event(idx).score], 10, length(idx)), 2);
        [ERP, se, z] = plot_eq_subj(EEG, ads(i), subj(j));
        ERPm = squeeze(mean(ERP(:,ch,:),1));
        ERPs(j,:) = ERPm;
%         subplot(3,4,i)
%         plot(t, ERPm)
%         title(['Subj ', subj{j}, ', Ad: ', num2str(i)])
    end
    subplot(3,4,j)
    plot(t, mean(ERPs, 1), 'LineWidth', 3)
    title(['Subj ', subj{j}])
end