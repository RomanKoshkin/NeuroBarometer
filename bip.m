clc
load('scores.mat')
% load('/Volumes/Transcend/NeuroBarometer/beeps_1/NeoRec_2018-07-09_16-19-17/NeoRec_2018-07-09_16-19-17_downsampled.mat');
EEG = pop_loadset('filepath', '/Volumes/Transcend/NeuroBarometer/beeps_1/NeoRec_2018-07-09_16-19-17', 'filename', 'NeoRec_2018-07-09_16-19-17_downsampled_ICAcleaned.mat');
% EEG = pop_loadset('filepath', '/Volumes/Transcend/NeuroBarometer/beeps_1/', 'filename', 'NeoRec_2018-07-05_15-33-44_downsampled.mat');


%% ERP and N1 for all the epochs:
clc
clearvars -except EEG scores_9july scores_5july a
chan = 17;
texts = [1:25];
type = 'median';
Lb = 57;
Ub = 65;
t = linspace(-100, 500, 121);
M = eye(63);
[Gavg, X, N1] = ERPs(Lb, Ub, EEG, t, 17, texts, M, type);

%% Biggest component:
[~, X, ~] = ERPs(Lb, Ub, EEG, t, 17, [1:50], eye(63), type);
x = squeeze(mean(X,1));

% we either use the eig function on the data covariance matrix, or the svd
% function to get the same eigenvectors:
% https://www.quora.com/What-is-an-intuitive-explanation-of-the-relation-between-PCA-and-SVD
[V,D] = eig(x*x');
% sort the eigenvenctors and eigenvalues in descending order (eig doesn't do it by default):
[d,ind] = sort(diag(D), 'descend');
D = D(ind,ind);
V = V(:,ind);

C = V'*x;
% subplot(3,1,2)
color = {'b','r', 'y'};
for i = 1:3
    plot(t, C(i,:), 'LineWidth', 2, 'Color', color{i})
    hold on
end
plot(t, squeeze(mean(X(:,chan,:),1)), 'Color', 'k', 'LineWidth', 2)
tit = title({['Grand Average @ ', EEG.chanlocs(17).labels, ' and'];...
    'several components computed on the entire ERP waveform'})
tit.FontSize = 14;
S.Vertices = [t(Lb) -4; t(Lb) 6; t(Ub) 6; t(Ub) -4];
S.Faces = [1 2 3 4];
S.EdgeColor = 'none';
S.FaceAlpha = 0.25;
patch(S)
grid on
vline(0); hline(0)

%% Compute eigenvectors on a selected window:
[~, X, ~] = ERPs(Lb, Ub, EEG, t, 17, [1:50], eye(63), type);
x_trg = squeeze(mean(X(:,:,Lb:Ub),1));

% we either use the eig function on the data covariance matrix, or the svd
% function to get the same eigenvectors:
% https://www.quora.com/What-is-an-intuitive-explanation-of-the-relation-between-PCA-and-SVD
[V_trg,D_trg] = eig(x_trg*x_trg');
% sort the eigenvenctors and eigenvalues in descending order (eig doesn't do it by default):
[d_trg,ind_trg] = sort(diag(D_trg), 'descend');
D_trg = D_trg(ind_trg,ind_trg);
V_trg = V_trg(:,ind_trg);

C_trg = V_trg'*x;
% subplot(3,1,2)
color = {'b','r', 'y'};
figure
for i = 1:3
    plot(t, C_trg(i,:), 'LineWidth', 2, 'Color', color{i})
    hold on
end
plot(t, squeeze(mean(X(:,chan,:),1)), 'Color', 'k', 'LineWidth', 2)
tit = title({['Grand Average @ ', EEG.chanlocs(17).labels, ' and'];...
    'several components computed on the TR'})
tit.FontSize = 14;
S.Vertices = [t(Lb) -4; t(Lb) 6; t(Ub) 6; t(Ub) -4];
S.Faces = [1 2 3 4];
S.EdgeColor = 'none';
S.FaceAlpha = 0.25;
patch(S)
grid on
vline(0); hline(0)

%% leave in only the physiologically plausible components and back-project to sensor space:
good_components = [1];
leave_in = ismember(1:63, good_components);

% % zero out all the components but the good ones:
% C_lean = C;
% C_lean(~leave_in,:) = 0;
% 
% % back-project to the sensor space:
% x_hat1 = V * C_lean; % V' could as well be inv(V), since V is orthogonal

% or (which would be the same) we could just zero-out the uninteresting
% eigenvectors;
V_clean1 = V;
V_clean1(:,~leave_in) = 0;
x_hat1 = V * V_clean1' * x;

V_clean2 = V_trg;
V_clean2(:,~leave_in) = 0;
x_hat2 = V * V_clean2' * x;

figure
plot(t, x(chan,:), 'k', t, x_hat1(17,:), 'b', t, x_hat2(17,:), 'r')
title(['Grand Average @ Cz back-projected into the channel space from components', sprintf('% i', good_components)])
leg = legend(   ['Raw ERP @ channel ', EEG.chanlocs(17).labels],...
                ['Back projection from selected components (entire ERP)'],...
                ['Back projection from selected components (TR [',...
                num2str([t(Lb) t(Ub)]), ' ms])']);
leg.FontSize = 14;
S.Vertices = [t(Lb) -2; t(Lb) 2; t(Ub) 2; t(Ub) -2];
S.Faces = [1 2 3 4];
S.EdgeColor = 'none';
S.FaceAlpha = 0.25;
patch(S)
grid on
vline(0, 'k'); hline(0, 'k')

%% component topoplots:
figure
for i = 1:3
    component_number = i;
    % since eigenvectors (orthogonal direction of maximum variances)
    % are (in) columns, we can take the columns and plot the
    % direction of the biggest variance on the topoplot (right?).
    xx = sign(mean(V(:,component_number)));
    subplot(2,3,i)
    topoplot(V(:,component_number).*xx, EEG.chanlocs,'style','both','electrodes','labelpoint');
    title(['component number: ', num2str(component_number)])
end
for i = 1:3
    component_number = i;
    % since eigenvectors (orthogonal direction of maximum variances)
    % are (in) columns, we can take the columns and plot the
    % direction of the biggest variance on the topoplot (right?).
    xx = sign(mean(V_trg(:,component_number)));
    subplot(2,3,i+3)
    topoplot(V_trg(:,component_number).*xx, EEG.chanlocs,'style','both','electrodes','labelpoint');
    title(['component number: ', num2str(component_number)])
end

%% analyze windows:
project_on_clean = 0;
var_of_interest = 4;

% text numbers in set A and set B:
A = find(scores_9july(var_of_interest,:)<=3);
B = find(scores_9july(var_of_interest,:)>=7);

type = 'median';
t = linspace(-100, 500, 121);

[t(Lb) t(Ub)]

if project_on_clean==1
    M = V_clean*V';
else
    M = eye(63);
end

figure
[Gavg, X, N1_a] = ERPs(Lb, Ub, EEG, t, chan, A, M, type);
plot(t, Gavg(chan,:))
hold on

[Gavg, X, N1_b] = ERPs(Lb, Ub, EEG, t, chan, B, M, type);
plot(t, Gavg(chan,:))

[~,p] = ttest2(N1_a, N1_b, 'alpha', 0.05, 'vartype', 'unequal')

leg = legend('low scores', 'high scores');
leg.FontSize = 14;
hline(0); vline(0)
tit = title({num2str(a{var_of_interest});['p-value = : ', num2str(p)]});
tit.FontSize = 14;

S.Vertices = [t(Lb) -2; t(Lb) 2; t(Ub) 2; t(Ub) -2];
S.Faces = [1 2 3 4];
S.EdgeColor = 'none';
S.FaceAlpha = 0.25;
patch(S)
grid



