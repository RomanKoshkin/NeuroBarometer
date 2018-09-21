close all
load('scores.mat')

% EEG = pop_loadset('filepath', '/Volumes/Transcend/NeuroBarometer/beeps_1/NeoRec_2018-07-09_16-19-17', 'filename', 'NeoRec_2018-07-09_16-19-17_downsampled_ICAcleaned.mat');
% EEG = pop_loadset('filepath', '/Volumes/Transcend/NeuroBarometer/beeps_1/NeoRec_2018-08-10_19-44-48/', 'filename', 'NeoRec_2018-08-10_19-44-48.mat');
EEG = pop_loadset('filepath', '/Volumes/Transcend/NeuroBarometer/beeps_1/NeoRec_2018-07-06_14-02-33/', 'filename', 'NeoRec_2018-07-06_14-02-33.mat');

scores = scores_6july;
clearvars -except EEG a scores


% EEG = pop_loadset('filepath', '/Volumes/Transcend/NeuroBarometer/beeps_1/NeoRec_2018-07-04_22-18-39', 'filename', 'NeoRec_2018-07-04_22-18-39_ds,filt.mat');
% scores = scores_4july;
% clearvars -except EEG a scores

%% ___START PARAMS___
good_components = [1];          
project_on_clean = 1;           % 0 or 1
PCA_on_scores = 1;              % 0 or 1
plot_and_test_components = 1;   % 0 or 1
var_of_interest = 2;
quant = [0.33 0.66];
chan = 17;

% *sig
% quant (0.2/0.8, PCA=1, proj=1, good=1, VOI=3, N1)
% quant (0.2/0.8, PCA=1, proj=0, good=1, VOI=3, N1)


% P1 (9july)
% Lb = 32;
% Ub = 40;

% N1 (9july)
Lb = 46;
Ub = 55;

% N1 (5july)
% Lb = 34;
% Ub = 41;

% P2
% Lb = 57;
% Ub = 65;

% N2
% Lb = 72;
% Ub = 80;

% ___END PARAMS___

leave_in = ismember(1:63, good_components);

t = linspace(-100, 500, 121);

[~, X, ~] = ERPs(Lb, Ub, EEG, t, chan, [1:50], eye(63), 'median');
x_trg = squeeze(mean(X(:,:,Lb:Ub),1));
x = squeeze(mean(X,1));

% we either use the eig function on the data covariance matrix, or the svd
% function to get the same eigenvectors:
% https://www.quora.com/What-is-an-intuitive-explanation-of-the-relation-between-PCA-and-SVD
% [V_trg, D_trg] = eig(x_trg*x_trg');
% [d_trg,ind_trg] = sort(diag(D_trg), 'descend');
% D_trg = D_trg(ind_trg,ind_trg);
% V_trg = V_trg(:,ind_trg);
% WE USE SVD INSTEAD OF EIG (RESULTS VARY IMPERCEPTIBLY)
[V_trg, S_trg, ~] = svd(x_trg);


V_clean = V_trg;
% zero-out the uninteresting eigenvectors
V_clean(:,~leave_in) = 0;

x_hat = V_trg * V_clean' * x;
% filter out everything but the 1st component
% x_hat = V_trg(:,1) * V_trg(:,1)' * x; % same as above

PCs = V_clean' * x;
figure
plot(t, x(chan,:), 'k', t, x_hat(chan,:), t, PCs(1,:))
hold on

s.Vertices = [t(Lb) -2; t(Lb) 2; t(Ub) 2; t(Ub) -2];
s.Faces = [1 2 3 4];
s.EdgeColor = 'none';
s.FaceAlpha = 0.25;
patch(s)
grid on
leg = legend(   ['Raw ERP @ channel ', EEG.chanlocs(chan).labels],...
                ['Back projection from selected components (TR [',...
                num2str([t(Lb) t(Ub)]), ' ms])'],...
                'First Component');
leg.FontSize = 14;
hline(0); vline(0)
%%
figure
for i = 1:3
    component_number = i;
    % since eigenvectors (orthogonal direction of maximum variances)
    % are (in) columns, we can take the columns and plot the
    % direction of the biggest variance on the topoplot (right?).
    xx = sign(mean(V_trg(:,component_number)));
    subplot(1,3,i)
    topoplot(V_trg(:,component_number).*xx, EEG.chanlocs,'style','both','electrodes','labelpoint');
    tit = title(['component number: ', num2str(component_number)]);
    tit.FontSize = 14;
end
%% analyze windows:

[transf, mapped_transf] = plot_s(scores);

p(1,1:2) = [0.582 0.582];
p(2,1:2) = [0.605 0.605];
p(3,1:2) = [0.63 0.63];

if PCA_on_scores == 1
    annotation('arrow',p(var_of_interest,:), [0.98 0.93],'Color',[1 0 0]);
end

if PCA_on_scores == 0
    % text numbers in set A and set B:
    cutoff_val = quantile(scores(var_of_interest,:), quant);
    figure(3)
    subplot(2,2,3)
    histogram(scores(var_of_interest,:), 10)
    A = find(scores(var_of_interest,:) <= cutoff_val(1));
    B = find(scores(var_of_interest,:) >= cutoff_val(2));
end
if PCA_on_scores == 1
    % text numbers in set A and set B:
    cutoff_val = quantile(mapped_transf(var_of_interest,:), quant)
    figure(3)
    subplot(2,2,3)
    histogram(mapped_transf(var_of_interest,:), 10)
    A = find(mapped_transf(var_of_interest,:) <= cutoff_val(1));
    B = find(mapped_transf(var_of_interest,:) >= cutoff_val(2));
    
end

title('Distribution of responses in component');
vline(cutoff_val(1), 'r', 'cutoff_1')
vline(cutoff_val(2), 'r', 'cutoff_2')

type = 'median';
t = linspace(-100, 500, 121);

[t(Lb) t(Ub)]

if project_on_clean==1
      if plot_and_test_components == 1
          chan = good_components;
          M = V_trg';
          addi = 'Components (i.e. raw ERPs projected onto the eigenvectors)';
      else
          addi = ['ERPs back-projected from component ', num2str(good_components)];
          M = V_trg*V_clean'; % transformation matrix (project on SOME of the basis vectors, then back project on ALL the vectors
          %     M = V_clean * V_trg'; % which gives the same result as above
      end

else
    M = eye(63);
    addi = 'RAW ERPs (no projection)';
end

figure
subplot(2,1,1)

[Gavg_A, X_a, N1_a] = ERPs(Lb, Ub, EEG, t, chan, A, M, type);
plot(t, Gavg_A(chan,:))
hold on

[Gavg_B, X_b, N1_b] = ERPs(Lb, Ub, EEG, t, chan, B, M, type);
plot(t, Gavg_B(chan,:))

[~,p] = ttest2(N1_a, N1_b, 'alpha', 0.05, 'vartype', 'unequal')

leg = legend('low scores', 'high scores');
leg.FontSize = 14;
hline(0); vline(0)

if PCA_on_scores == 0
    tit = title({
        num2str(a{var_of_interest})
        ['p-value = : ', num2str(p)];
        addi});
end
if PCA_on_scores == 1
    tit = title({
        ['component ' num2str(var_of_interest) ' of the scores matrix'];
        ['p-value = : ', num2str(p)];
        addi});
end
tit.FontSize = 14;

s.Vertices = [t(Lb) -2; t(Lb) 2; t(Ub) 2; t(Ub) -2];
s.Faces = [1 2 3 4];
s.EdgeColor = 'none';
s.FaceAlpha = 0.25;
patch(s)
grid

subplot(2,1,2)
% prettify for plotting purposes:
X_a_pretty = X_a; X_b_pretty = X_b;
% X_a_pretty(X_a_pretty>10)=10;
% X_a_pretty(X_a_pretty<-10)=-10;
% X_b_pretty(X_b_pretty>10)=10;
% X_b_pretty(X_b_pretty<-10)=-10;

X_a_pretty(X_a_pretty>0) = log(X_a_pretty(X_a_pretty>0));
X_a_pretty(X_a_pretty<0) = -log(-X_a_pretty(X_a_pretty<0));
X_b_pretty(X_b_pretty>0) = log(X_b_pretty(X_b_pretty>0));
X_b_pretty(X_b_pretty<0) = -log(-X_b_pretty(X_b_pretty<0));

imagesc(squeeze(X_b_pretty(:,chan,:)), [-3 3])
ylabel('Trials')
xlabel('Time')
im = gca;
im.XTick = linspace(1, 121, 7);
im.XTickLabel = linspace(-100, 500, 7);
vline(21)
tit = title('Single Trials in Highly Scored Commercials');
tit.FontSize = 14;


%%
M = eye(63);
[Gavg_A, X_a, N1_a] = ERPs(Lb, Ub, EEG, t, chan, A, M, type);
[Gavg_B, X_b, N1_a] = ERPs(Lb, Ub, EEG, t, chan, B, M, type);
D = squeeze(mean(X_b,1)) - squeeze(mean(X_a,1));
[U_full,~,~] = svd(D); % PCA on the entire timecourse of the difference wave (B - A)
[U_TR,~,~] = svd(D(:,Lb:Ub)); % PCA on the TR of the difference wave (B - A)

% components of the difference wave:
D_comps_full = U_full' * D;
D_comps_TR = U_TR' * D;

% back-projections of the biggets components into the channel space
U_full_clean = U_full;
U_full_clean(:,2:end) = 0;
U_TR_clean = U_TR;
U_TR_clean(:,2:end) = 0;

D_backproj_full = U_full * U_full_clean' * D;
D_backproj_TR = U_TR * U_TR_clean' * D;

figure
subplot(1,2,1)
plot(t, D_comps_full(1,:)); vline(0); hline(0)
hold on
plot(t, D_comps_TR(1,:)); vline(0); hline(0)
plot(t, D(17,:), 'k', 'LineWidth', 2); vline(0); hline(0)
grid on
leg = legend(...
    'Component 1 (computed on full timecourse)',...
    'Component 1 computed on TR',...
    'Raw difference wave (B - A) @ Cz');
leg.FontSize = 14;
s.Vertices = [t(Lb) -2; t(Lb) 2; t(Ub) 2; t(Ub) -2];
s.Faces = [1 2 3 4];
s.EdgeColor = 'none';
s.FaceAlpha = 0.25;
patch(s)

subplot(1,2,2)
plot(t, D_backproj_full(17,:)); vline(0); hline(0)
hold on
plot(t, D_backproj_TR(17,:)); vline(0); hline(0)
plot(t, D(17,:), 'k', 'LineWidth', 2); vline(0); hline(0)
leg = legend(...
    'Back-projection of comp. 1 (computed on full timecourse) into chan.space (@ Cz)',...
    'Back-projection of comp. 1 (computed on TR) into chan.space (@ Cz)',...
    'Raw difference wave (B - A) @ Cz');

leg.FontSize = 14;
grid on
s.Vertices = [t(Lb) -2; t(Lb) 2; t(Ub) 2; t(Ub) -2];
s.Faces = [1 2 3 4];
s.EdgeColor = 'none';
s.FaceAlpha = 0.25;
patch(s)

%% Functions:
function [transf, mapped_transf] = plot_s(scores)
    ans = corr(scores',scores');
    figure
    subplot(2,2,1)
    imagesc(ans)
    colorbar
    tit = title('Covariance Matrix');
    tit.FontSize = 14;

    [U,S,~] = svd(scores);
    subplot(2,2,2)
    imagesc(-U)
    colorbar
    tit = title('SVD');
    tit.FontSize = 14;

    subplot(2,2,4)
    plot(diag(S(1:10,1:10))./10)
    tit = title('Singular Values');
    tit.FontSize = 14;
    grid on
    colorbar

    transf = -U(:,1:3)' * scores;
    mapped_transf = mapminmax(transf, 1,10);
end