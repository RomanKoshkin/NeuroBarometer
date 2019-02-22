% params
chan = 17;
responses = [EEG.event.response1]';
t = linspace(-100, 500, 121);
figure;
N_up = 1;
question = 2;
ads = [5 17];

m_rating = zeros(1,2);
c = 0;
a = 0;
for ad_id = ads
    c = c + 1; 
    lat_ids = find(ismember({EEG.event.type}, num2str(ad_id)));
    m_rating(c) = mean(responses(lat_ids,question));
    TR = [find(t==130):find(t==170)];
    
    alpha = get_alpha_2(chan, TR, lat_ids);
    SE_a(c) = std(alpha)/sqrt(length(alpha)*N_up);
    m_alpha(c) = mean(alpha);
    
    [X, N1, Z] = ERPs_2(chan, TR, lat_ids);
    SE = std(Z,1)/sqrt(size(Z,1)*N_up);
    subplot(1,2,1)
    errorbar(t, X(chan,:), SE)
    grid on; vline(0); hline(0); hold on
 
end
leg = legend({['ad ', num2str(ads(1)),'=', num2str(m_rating(1))],...
        ['ad ', num2str(ads(2)),'=', num2str(m_rating(2))]});
leg.FontSize = 14;

subplot(1,2,2)
err = errorbar(1:2, m_alpha, SE_a);
err = gca;
err.XLim = [0 3];
text([1 2], m_alpha, num2cell(round(m_alpha,2)))

error('code stopped')
%%
c = 0;
quant = [0.9 0.1];
for ad_id = 1:50
    c = c + 1;
    lat_ids = find(ismember({EEG.event.type}, num2str(ad_id)));
    m_rating(c) = mean(responses(lat_ids,question));
end

figure
q1 = quantile(m_rating,quant(1));
q2 = quantile(m_rating,quant(2));

locsq1 = find(m_rating>q1);
locsq2 = find(m_rating<q2);

scatter(1:50, m_rating, 'ow')
lsline
hold on

plot(1:50, m_rating, locsq1, m_rating(locsq1),'or', locsq2, m_rating(locsq2),'og')
grid on

hline(q1, 'g', [num2str(quant(1)), 'th quantile'])
hline(q2, 'g', [num2str(quant(2)), 'th quantile'])

text(locsq1, m_rating(locsq1), num2cell(round(m_rating(locsq1),1)))
text(locsq2, m_rating(locsq2), num2cell(round(m_rating(locsq2),1)))

%%
figure
hm = zeros(length(locsq1),length(locsq2));
sc = zeros(length(locsq1),length(locsq2));
alpha_sc = zeros(length(locsq1),length(locsq2));

TR = [find(t==130):find(t==170)];
c = 0;
for i = 1:length(locsq1)
    for j = 1:length(locsq2)
        sc(i,j) =...
            mean(responses(  find(ismember({EEG.event.type}, num2str(locsq1(i)))),  question)) -...
            mean(responses(  find(ismember({EEG.event.type}, num2str(locsq2(j)))),  question));
            
        c = c + 1;
        lat_ids_i = find(ismember({EEG.event.type}, num2str(locsq1(i))));
        lat_ids_j = find(ismember({EEG.event.type}, num2str(locsq2(j))));

        [X_i, N1_i, Z_i] = ERPs_2(chan, TR, lat_ids_i);
        SE_i = std(Z_i,1)/sqrt(size(Z_i,1)*N_up);
        alpha_i = mean(get_alpha_2(chan, TR, lat_ids_i));
        
        [X_j, N1_j, Z_j] = ERPs_2(chan, TR, lat_ids_j);
        SE_j = std(Z_j,1)/sqrt(size(Z_j,1)*N_up);
        alpha_j = mean(get_alpha_2(chan, TR, lat_ids_j));
        
        
        hm(i,j) = mean(N1_i)-mean(N1_j);
        alpha_sc(i,j) = alpha_j - alpha_i;
        
        subplot(length(locsq1),length(locsq2),c)
        plot(t, X_i(chan,:),t,X_j(chan,:))
        title(['high: ', num2str(locsq1(i)),' - low: ', num2str(locsq2(j))])
    end
end


figure

subplot(2,2,1)
imagesc(hm);
ax = gca;
ax.XTickLabelMode = 'manual';
ax.XTick = [1:length(locsq2)];
ax.XTickLabel = num2cell(locsq2);
ax.YTickLabelMode = 'manual';
ax.YTick = [1:length(locsq1)];
ax.YTickLabel = num2cell(locsq1);
ax.YLabel.String = 'high scores';
ax.XLabel.String = 'low scores';
ax.Title.String = 'N1 high - N1 low';
colorbar

subplot(2,2,2)
imagesc(sc)
ax = gca;
ax.XTickLabelMode = 'manual';
ax.XTick = [1:length(locsq2)];
ax.XTickLabel = num2cell(locsq2);
ax.YTickLabelMode = 'manual';
ax.YTick = [1:length(locsq1)];
ax.YTickLabel = num2cell(locsq1);
ax.YLabel.String = 'high scores';
ax.XLabel.String = 'low scores';
ax.Title.String = 'high - low scores';
colorbar

subplot(2,2,3)
scatter(reshape(sc,1,[]),reshape(hm,1,[]));
ax = gca;
ax.Title.String = 'Correlation of N1 difference and Score differnce';
lsline

subplot(2,2,4)
imagesc(alpha_sc)
ax = gca;
ax.XTickLabelMode = 'manual';
ax.XTick = [1:length(locsq2)];
ax.XTickLabel = num2cell(locsq2);
ax.YTickLabelMode = 'manual';
ax.YTick = [1:length(locsq1)];
ax.YTickLabel = num2cell(locsq1);
ax.YLabel.String = 'high scores';
ax.XLabel.String = 'low scores';
ax.Title.String = 'alpha LOW - alpha HIGH';
colorbar