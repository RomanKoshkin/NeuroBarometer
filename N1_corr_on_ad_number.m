p_prominence = 0.05;
t = linspace(-100, 500, 121);
chan = 17;
ad_nums = {EEG.event.type};
% N1 = struct;
% P1 = struct;

for n = 1:50;
    
    ad_idx = find(ismember(ad_nums, num2str(n)));
    lat_n = [EEG.event(ad_idx).latency];
    X_n = ERPs_1(EEG, lat_n);
    X_n_GA = squeeze(mean(X_n,1));

    % plot(t, X_n_GA(chan,:))
    % hold on; grid on

    % find minima:
    [pks_min_lo, locs_min_lo] = findpeaks(-X_n_GA(chan,:), t, 'MinPeakProminence', p_prominence);
    pks_min_lo = -pks_min_lo;

    % find maxima:
    [pks_max_lo, locs_max_lo] = findpeaks(X_n_GA(chan,:), t, 'MinPeakProminence', p_prominence);


    N1_latency_lo = locs_min_lo(locs_min_lo>=100 & locs_min_lo<=200);
    N1_latency_lo = chk_latency(N1_latency_lo,t,-X_n_GA,chan)
    % text(N1_latency_lo, pks_min_lo(locs_min_lo==N1_latency_lo), 'N1')

    P1_latency_lo = locs_max_lo(locs_max_lo>=60 & locs_max_lo<=120);
    P1_latency_lo = chk_latency(P1_latency_lo,t,X_n_GA,chan)
    % text(P1_latency_lo, pks_max_lo(locs_max_lo==P1_latency_lo), 'P1')

    % TR times (40-ms window surrounding the observed peak)
    N1_sample_nos_lo = find(t==N1_latency_lo-20):find(t==N1_latency_lo+20);
    P1_sample_nos_lo = find(t==P1_latency_lo-20):find(t==P1_latency_lo+20);

    % plot(t(P1_sample_nos_lo), squeeze(mean(X_n(:, chan, P1_sample_nos_lo), 1)), 'b', 'LineWidth', 3)
    % plot(t(N1_sample_nos_lo), squeeze(mean(X_n(:, chan, N1_sample_nos_lo), 1)), 'b', 'LineWidth', 3)

    avg_P1_lo = avg_amp_all(X_n,chan,t, P1_sample_nos_lo);
    % hline(mean(avg_P1_lo))

    avg_N1_lo = avg_amp_all(X_n,chan,t, N1_sample_nos_lo);
    % hline(mean(avg_N1_lo))

    % vline(N1_latency_lo)
    % vline(P1_latency_lo)
    
    N1(n).M = mean(avg_N1_lo);
    N1(n).SE = std(avg_N1_lo)/sqrt(length(avg_N1_lo));
    
    P1(n).M = mean(avg_P1_lo);
    P1(n).SE = std(avg_P1_lo)/sqrt(length(avg_P1_lo));
    
    disp(n)
end

csvwrite('N1.csv', [[N1.M]' [N1.SE]'])
csvwrite('P1.csv', [[P1.M]' [P1.SE]'])