%% 1 Get test & train data tensors and labels
cd('/Users/RomanKoshkin/Documents/MATLAB/NeuroBarometer')

ads = [3    14    15    19    23    24    25    30    39    47];
elect_subj = {'Deryabin', 'Kabanov', 'Kabanova', 'Sukhanova', 'Vishnyakova', 'Karpinskaya', 'Orlichenya'};
Tvar = 2;

[ERP, se, z] = plot_eq_subj(EEG, ads, elect_subj);

train_idx = randsample(size(ERP,1), round(size(ERP,1)*0.8));
test_idx = find(~ismember(1:size(ERP,1), train_idx))';

ERP_train = ERP(train_idx,:,:);
z_train = z(train_idx, Tvar);

ERP_test = ERP(test_idx,:,:);
z_test = z(test_idx, Tvar);

% save('/Users/RomanKoshkin/Downloads/ERP_train.mat', 'ERP_train', 'z_train')
%% 2 Fit the model (SPoC_lambda):
z_train = z_train - mean(z_train);
z_train = z_train/std(z_train);

C = zeros(size(ERP_train,1),32,32);
C_z = zeros(size(ERP_train,1),32,32);

for i = 1:size(ERP_train,1)
    C(i,:,:) = cov(squeeze(ERP_train(i,:,:))');
    C_z(i,:,:) = squeeze(C(i,:,:)) * z_train(i);
end
C_z = squeeze(mean(C_z,1));
C_beau = squeeze(mean(C,1));


[V,D] = eig(C_z, C_beau);
% [V,D] = eig(C_beau, C_z);
[~, order] = sort(diag(D),'descend');
V = V(:,order);
D = D(:,order);

w = V(:,1);

figure;
subplot(1,2,1)
topoplot(w, EEG.chanlocs,'style','both','electrodes','labelpoint');
tit = title('w from SPoC_{\lambda}'); tit.FontSize = 14;
subplot(1,2,2)
topoplot(w'*C_beau, EEG.chanlocs,'style','both','electrodes','labelpoint');
tit = title('w^{T} C from SPoC_{\lambda}'); tit.FontSize = 14;

% - compute correlation with the weights found:

enum = (w' * C_z * w)^2;
denom = zeros(size(C,1), 1);
for i = 1:size(C,1)
    denom(i) = (w' * (squeeze(C(i,:,:)) - C_beau) * w)^2;
end
denom = mean(denom);
f = sqrt(enum/denom);
%% 2?
z_tilde = zeros(size(C,1), 1);
for i = 1:size(C,1)
    z_tilde(i) = w' * (squeeze(C(i,:,:)) - C_beau) * w;
end
corr(z_train,z_tilde)

%% 3 compare the filters from SPoC_r
load('/Users/RomanKoshkin/Downloads/w.mat')
w = w';
enum = (w' * C_z * w)^2;
denom = zeros(size(C,1), 1);
for i = 1:size(C,1)
    denom(i) = (w' * (squeeze(C(i,:,:)) - C_beau) * w)^2;
end
denom = mean(denom);
f = enum/denom;

figure;
subplot(1,2,1)
topoplot(w, EEG.chanlocs,'style','both','electrodes','labelpoint');
tit = title('w from SPoC_{r}'); tit.FontSize = 14;
subplot(1,2,2)
topoplot(w'*C_beau, EEG.chanlocs,'style','both','electrodes','labelpoint');
tit = title('w^{T} * C from SPoC_{r}'); tit.FontSize = 14;
%%
load('/Users/RomanKoshkin/Downloads/w.mat')
% load('/Users/RomanKoshkin/Downloads/w_sgd.mat')
% load('/Users/RomanKoshkin/Downloads/w_sgd_1-40.mat')
% load('/Users/RomanKoshkin/Downloads/w_su.mat')
w = w';

z = z(:,2);

z = z - mean(z);
z = z/std(z);

C = zeros(size(ERP,1),32,32);
C_z = zeros(size(ERP,1),32,32);

for i = 1:size(ERP,1)
    C(i,:,:) = cov(squeeze(ERP(i,:,:))');
    C_z(i,:,:) = squeeze(C(i,:,:)) * z(i);
end
C_z = squeeze(mean(C_z,1));
C_beau = squeeze(mean(C,1));

enum = (w' * C_z * w)^2;
denom = zeros(size(C,1), 1);
for i = 1:size(C,1)
    denom(i) = (w' * (squeeze(C(i,:,:)) - C_beau) * w)^2;
end
denom = mean(denom);
f = enum/denom;

figure;
subplot(1,2,1)
topoplot(w, EEG.chanlocs,'style','both','electrodes','labelpoint');
tit = title('w (plain & straight)'); tit.FontSize = 14;
subplot(1,2,2)
topoplot(w'*C_beau, EEG.chanlocs,'style','both','electrodes','labelpoint');
tit = title('w^{T} * C'); tit.FontSize = 14;