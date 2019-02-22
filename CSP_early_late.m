% load('/Volumes/Transcend/NeuroBarometer/X_early_late.mat')
load('/Volumes/Transcend/NeuroBarometer/beeps_1/X_early_late_alpha.mat')
% load('/Volumes/Transcend/NeuroBarometer/beeps_1/early_late_alpha3.mat')


load('/Volumes/Transcend/NeuroBarometer/beeps_1/chanlocs.mat')
t = linspace(-100, 500, 121);

per_trial = 1;
s = 1;
e = 121;
% s = 31;
% e = 41;

if per_trial == 1
    % CSP on early and late
    Xe = zeros(size(X_early,1),63,63);
    Xl = zeros(size(X_early,1),63,63);

    % get per-trial covariance matrices, put them in 3D array:
    for i = 1:size(X_early,1)
        Re = squeeze(X_early(i,:,s:e))*squeeze(X_early(i,:,s:e))';
        Re = Re/trace(Re);
        Xe(i,:,:) = Re;
        Rl = squeeze(X_late(i,:,s:e))*squeeze(X_late(i,:,s:e))';
        Rl = Rl/trace(Rl);
        Xl(i,:,:) = Rl;
        disp(i)
    end

    % get average covariance matrices for each condition (early vs. late)
    Xe = squeeze(mean(Xe,1));
    Xl = squeeze(mean(Xl,1));
else
    Xe = squeeze(mean(X_early,1));
    Xl = squeeze(mean(X_late,1));
    
    Xe = (Xe * Xe')/trace(Xe * Xe');
    Xl = (Xl * Xl')/trace(Xl * Xl');
end

% get CSP:
[V, D] = eig(Xe, Xe+Xl); % as described by Christian Kothe
% [V, D] = eig(inv(Xe)*Xl); % as described in wikipedia

[~, order] = sort(diag(D),'descend');
V = V(:,order);
d = zeros(63,63);
for i = 1:63
    d(i,i) = D(order(i),order(i));
end

topos = V;

figure;
for i = 1:4
    subplot(2,4,i)
    topoplot(topos(:,i), chanlocs,'style','both','electrodes','labelpoint');
    title(num2str(i))
    subplot(2,4,4+i)
    topoplot(topos(:,64-i), chanlocs,'style','both','electrodes','labelpoint');
    title(num2str(64-i))
end

figure
plot(t, squeeze(mean(X_early(:,17,:),1)))
hold on
plot(t, squeeze(mean(X_late(:,17,:),1)))
legend({'early', 'late'})