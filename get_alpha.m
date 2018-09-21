function [A] = get_alpha(EEG, X_lo, X_hi, X_mid, k, p1, a, chan, single_mode)
    fs = EEG.srate;
    number_of_frequencies = 20;

    alpha_pow_lo = zeros(length(X_lo), 1);
    alpha_pow_hi = zeros(length(X_hi), 1);

    for i = 1:length(X_lo)
        signal = squeeze(X_lo(i,chan,:));
        [pxx,f] = periodogram(signal,[], number_of_frequencies, fs, 'power', 'onesided');
        alpha_pow_lo(i) = pxx(2);
        disp (['Alpha low', num2str(i), ' of ', num2str(length(X_lo))])
    end

    for i = 1:length(X_hi)
        signal = squeeze(X_hi(i,chan,:));
        [pxx,f] = periodogram(signal,[], number_of_frequencies, fs, 'power', 'onesided');
        alpha_pow_hi(i) = pxx(2);
        disp (['Alpha high', num2str(i), ' of ', num2str(length(X_hi))])
    end

    for i = 1:length(X_mid)
        signal = squeeze(X_mid(i,chan,:));
        [pxx,f] = periodogram(signal,[], number_of_frequencies, fs, 'power', 'onesided');
        alpha_pow_mid(i) = pxx(2);
        disp (['Alpha mid', num2str(i), ' of ', num2str(length(X_mid))])
    end

    % truncate outliers:
    alpha_pow_lo(alpha_pow_lo>165) = 165;
    alpha_pow_mid(alpha_pow_mid>165) = 165;

    L = mean(alpha_pow_lo);
    H = mean(alpha_pow_hi);
    M = mean(alpha_pow_mid);
    
    x = [1 2 3];
    y = [L M H];
    err = [...
        std(alpha_pow_lo)/sqrt(length(alpha_pow_lo)) ...
        std(alpha_pow_mid)/sqrt(length(alpha_pow_mid)) ...
        std(alpha_pow_hi)/sqrt(length(alpha_pow_hi))];

%     subplot(1,2,1)
%     plot(alpha_pow_lo)
%     hold on
%     plot(alpha_pow_hi)
%     plot(alpha_pow_mid)
%     tit = title('Alpha power by trial');
%     tit.FontSize = 14;
%     subplot(1,2,2)
    
    if single_mode == 1
        subplot(1,1,1, 'Parent', p1)
    else
        subplot(4,3,k, 'Parent', p1)
    end
    
    eb = errorbar(x,y,err);
    eb.Parent.XLim = [0 4];
    eb.Parent.XTick = [1 2 3];
    
    eb.Parent.XTickLabel = {'low', 'mid', 'high'};
    eb.Parent.FontSize = 14;
    
    labels = [...
        repmat(1,length(alpha_pow_lo),1);...
        repmat(2,length(alpha_pow_mid),1);...
        repmat(3,length(alpha_pow_hi),1)...
        ];
    
    dat = [alpha_pow_lo; alpha_pow_mid'; alpha_pow_hi];
    p = anova1(dat, labels, 'off');
    
    tit_str = {a{k},['p = ', num2str(p)]};
    tit = title(tit_str);
    tit.FontSize = 14;
    
    
    % dim = [.2 .5 .3 .3];
    % str = {['P1: p = ', num2str(P_P1)], ['N1: p = ', num2str(P_N1)]};
    % % an = annotation(p, 'textbox',dim,'String',str,'FitBoxToText','on');
    % % an.FontSize = 14;
    % annotation(
end