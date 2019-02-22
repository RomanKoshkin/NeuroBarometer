% this function finds peaks, plots ERPs and returns stats.

function [tab] = plot_single_stat(X_lo_GA, X_hi_GA, X_lo, X_hi, t, k, p, tab, chan, single_mode)

if single_mode == 1
    subplot(1,1,1, 'Parent', p)
else
    subplot(4,3,k, 'Parent', p)
end

p_prominence = 0.05;

plot(t, X_lo_GA(chan,:))
hold on
plot(t, X_hi_GA(chan,:))
grid on


% find minima:
[pks_min_lo, locs_min_lo] = findpeaks(-X_lo_GA(chan,:), t, 'MinPeakProminence', p_prominence);
pks_min_lo = -pks_min_lo;
[pks_min_hi, locs_min_hi] = findpeaks(-X_hi_GA(chan,:), t, 'MinPeakProminence', p_prominence);
pks_min_hi = -pks_min_hi;
% text(locs_min+.02,pks_min,num2str((1:numel(pks_min))'))

% find maxima:

[pks_max_lo, locs_max_lo] = findpeaks(X_lo_GA(chan,:), t, 'MinPeakProminence', p_prominence);
[pks_max_hi, locs_max_hi] = findpeaks(X_hi_GA(chan,:), t, 'MinPeakProminence', p_prominence);
% text(locs_max+.02,pks_max,num2str((1:numel(pks_max))'))

N1_latency_lo = locs_min_lo(locs_min_lo>=100 & locs_min_lo<=200);
N1_latency_lo = chk_latency(N1_latency_lo,t,-X_lo_GA,chan)
N1_latency_hi = locs_min_hi(locs_min_hi>=100 & locs_min_hi<=200);
N1_latency_hi = chk_latency(N1_latency_hi,t,-X_hi_GA,chan)
text(N1_latency_lo, pks_min_lo(locs_min_lo==N1_latency_lo), 'N1')

P1_latency_lo = locs_max_lo(locs_max_lo>=60 & locs_max_lo<=120);
P1_latency_lo = chk_latency(P1_latency_lo,t,X_lo_GA,chan)
P1_latency_hi = locs_max_hi(locs_max_hi>=60 & locs_max_hi<=120);
P1_latency_hi = chk_latency(P1_latency_hi,t,X_hi_GA,chan)
text(P1_latency_lo, pks_max_lo(locs_max_lo==P1_latency_lo), 'P1')

% TR times (40-ms window surrounding the observed peak)
N1_sample_nos_lo = find(t==N1_latency_lo-20):find(t==N1_latency_lo+20);
P1_sample_nos_lo = find(t==P1_latency_lo-20):find(t==P1_latency_lo+20);
N1_sample_nos_hi = find(t==N1_latency_hi-20):find(t==N1_latency_hi+20);
P1_sample_nos_hi = find(t==P1_latency_hi-20):find(t==P1_latency_hi+20);

plot(t(P1_sample_nos_lo), squeeze(mean(X_lo(:, chan, P1_sample_nos_lo), 1)), 'b', 'LineWidth', 3)
plot(t(N1_sample_nos_lo), squeeze(mean(X_lo(:, chan, N1_sample_nos_lo), 1)), 'b', 'LineWidth', 3)
plot(t(P1_sample_nos_hi), squeeze(mean(X_hi(:, chan, P1_sample_nos_hi), 1)), 'r', 'LineWidth', 3)
plot(t(N1_sample_nos_hi), squeeze(mean(X_hi(:, chan, N1_sample_nos_hi), 1)), 'r', 'LineWidth', 3)

avg_P1_lo = avg_amp_all(X_lo,chan,t, P1_sample_nos_lo);
avg_P1_hi = avg_amp_all(X_hi,chan,t, P1_sample_nos_hi);
hline(mean(avg_P1_lo))
hline(mean(avg_P1_hi))

avg_N1_lo = avg_amp_all(X_lo,chan,t, N1_sample_nos_lo);
avg_N1_hi = avg_amp_all(X_hi,chan,t, N1_sample_nos_hi);
hline(mean(avg_N1_lo))
hline(mean(avg_P1_hi))

vline(N1_latency_lo)
vline(P1_latency_lo)

[~,P_N1] = ttest2(avg_N1_lo,avg_N1_hi, 'tail', 'right', 'vartype', 'unequal');
[~,P_P1] = ttest2(avg_P1_lo,avg_P1_hi, 'tail', 'right', 'vartype', 'unequal');

tab(k).M_P1_lo = mean(avg_P1_lo);
tab(k).M_P1_hi = mean(avg_P1_hi);
tab(k).SD_P1_lo = std(avg_P1_lo);
tab(k).SD_P1_hi = std(avg_P1_hi);
tab(k).N_P1_lo = length(avg_P1_lo);
tab(k).N_P1_hi = length(avg_P1_hi);
tab(k).P_P1 = P_P1;

tab(k).M_N1_lo = mean(avg_N1_lo);
tab(k).M_N1_hi = mean(avg_N1_hi);
tab(k).SD_N1_lo = std(avg_N1_lo);
tab(k).SD_N1_hi = std(avg_N1_hi);
tab(k).N_N1_lo = length(avg_N1_lo);
tab(k).N_N1_hi = length(avg_N1_hi);
tab(k).P_N1 = P_N1;

% ax = gca;
% 
% S = struct;
% S.Vertices = [N1_latency_lo-20 ax.YLim(1); N1_latency_lo-20 ax.YLim(2); N1_latency_lo+20 ax.YLim(2); N1_latency_lo+20 ax.YLim(1)];
% S.Faces = [1 2 3 4];
% S.EdgeColor = 'none';
% S.FaceAlpha = 0.25;
% patch(S)
% 
% S = struct;
% S.Vertices = [P1_latency_lo-20 ax.YLim(1); P1_latency_lo-20 ax.YLim(2); P1_latency_lo+20 ax.YLim(2); P1_latency_lo+20 ax.YLim(1)];
% S.Faces = [1 2 3 4];
% S.EdgeColor = 'none';
% S.FaceColor = 'red';
% S.FaceAlpha = 0.25;
% patch(S)

% dim = [.2 .5 .3 .3];
% str = {['P1: p = ', num2str(P_P1)], ['N1: p = ', num2str(P_N1)]};
% an = annotation(p, 'textbox',dim,'String',str,'FitBoxToText','on');
% an.FontSize = 14;

end