load('a.mat')
load('scores.mat')
load('lookup_tab.mat')
%%
eig_of_interest = 2;
g = [];
scores_tmp = [];
U = [];
all_scores = [];
for i = 1:11
    scores_tmp = eval(lookup_tab{i,2});
%     scores_tmp = scores_tmp - mean(scores_tmp,2);
    all_scores = cat(2, all_scores, scores_tmp);
    [U(:,:,i),~,~] = svd(scores_tmp);
end

% fix the eigs:
U(:,:,2:4) = U(:,:,2:4) * (-1);

U_m = squeeze(mean(U,3));

figure
for i = 1:11
    subplot(3,4,i)
    imagesc(squeeze(U(:,:,i))); colorbar;
end

U_m = U_m * (-1);
subplot(3,4,12)
imagesc(U_m); colorbar
tit = title('Average Eigenvectors');
tit.FontSize = 14;
ylabel('Questions')
xlabel('Eigenvectors')
ax = gca; ax.FontSize = 14;


% project and normalize the scores:

sc = mapminmax(U_m'* all_scores, 0,1);
qq = quantile(sc, [0.33 0.66]);

figure
dsp = 0;
for i = 1:11
    sc_tmp = sc(:,1+dsp:50+dsp);
    assignin('base', lookup_tab{i,2}, sc_tmp);
    subplot(3,4,i)
    histogram(sc_tmp); 
    tit = title(num2str(i));
    tit.FontSize = 14;
    dsp = dsp + 50;
end

subplot(3,4,12)
histogram(sc);
tit = title('histogram of all scores');
tit.FontSize = 14;
ax = gca;
ax.XLim = [0 1];

U_m(:,2)