%% save data in different passbands:

ads = [3    14    15    19    23    24    25    30    39    47];
elect_subj = {'Deryabin', 'Kabanov', 'Kabanova', 'Sukhanova', 'Vishnyakova', 'Karpinskaya', 'Orlichenya'};
Tvar = 2;

[ERP, se, z] = plot_eq_subj(EEG, ads, elect_subj);
train_idx = randsample(size(ERP,1), round(size(ERP,1)*0.8));
test_idx = find(~ismember(1:size(ERP,1), train_idx))';

passband = [[1 5]; [3 8]; [6 12]; [10 17]; [15 22]; [20 28]; [26 32]; [30 40]];

for i = 1:size(passband,1)
    [tmp_erp, ~, ~] = pop_eegfiltnew(EEG, passband(i,1), passband(i,2));
    assignin('base',['EEG_', num2str(i)], tmp_erp);
    [ERP, se, z] = plot_eq_subj(eval(['EEG_', num2str(i)]), ads, elect_subj);
    ERP_train = ERP(train_idx,:,:);
    z_train = z(train_idx, Tvar);
    save(['/Users/RomanKoshkin/Downloads/ERP_', num2str(i), '.mat'], 'ERP_train', 'z_train')
    clear tmp_erp ERP_train
    eval(['clear EEG_', num2str(i)])
end
%%
for i = 1:8
    figure('NumberTitle', 'off', 'Name', [num2str(passband(i,1)) '-' num2str(passband(i,2)), ' Hz'])
    load(['/Users/RomanKoshkin/Downloads/w', num2str(i), '.mat'])
    load(['/Users/RomanKoshkin/Downloads/C_', num2str(i), '.mat'])
    subplot(1,2,1)
    topoplot(w, EEG.chanlocs,'style','both','electrodes','labelpoint');
    tit = title('w from SPoC_{\lambda}'); tit.FontSize = 14;
    subplot(1,2,2)
    topoplot(w*C_beau, EEG.chanlocs,'style','both','electrodes','labelpoint');
    tit = title('w^{T} C from SPoC_{\lambda}'); tit.FontSize = 14;
end