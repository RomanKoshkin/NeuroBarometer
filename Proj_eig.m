%%
lambda = 0.1;
ch = 17;

% define TR and FR:
TR = 36:46;
FR = 1:21;
mERP = squeeze(mean(ERP, 1));

% correlation matrices for the target and flanker ranges:
C1 = mERP(:,TR)*mERP(:,TR)';
C2 = mERP(:,FR)*mERP(:,FR)';

C1 = C1 + lambda*trace(C1)/size(C1,1)*eye(size(C1,1));
C2 = C2 + lambda*trace(C2)/size(C2,1)*eye(size(C2,1));

[v1, d1] = eig(C1, C2);
H = eye(length(v1)); % for t


[~, order] = sort(diag(d1),'descend');
v1 = v1(:,order) * -1;
d1 = d1(:,order);
% v1 = v1*diag(1./sqrt(sum(v1.^2,1)));

figure
subplot(1,2,1)
topoplot(v1(:,1), EEG.chanlocs,'style','both','electrodes','labelpoint');
subplot(1,2,2)
plot(t, v1(:,1)' * H * mERP, 'LineWidth', 2)
hold on
plot(t, mERP(ch,:), 'LineWidth', 2)