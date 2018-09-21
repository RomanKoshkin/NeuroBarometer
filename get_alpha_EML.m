function [A] = get_alpha_EML(EEG, X_early, X_late, X_middle, k, p, a, chan, single_mode)
    fs = EEG.srate;
    number_of_frequencies = 20;

    alpha_pow_early = zeros(length(X_early), 1);
    alpha_pow_late = zeros(length(X_late), 1);

    for i = 1:length(X_early)
        signal = squeeze(X_early(i,chan,:));
        [pxx,f] = periodogram(signal,[], number_of_frequencies, fs, 'power', 'onesided');
        alpha_pow_early(i) = pxx(2);
        disp (['Alpha early ', num2str(i), ' of ', num2str(length(X_early))])
    end

    for i = 1:length(X_late)
        signal = squeeze(X_late(i,chan,:));
        [pxx,f] = periodogram(signal,[], number_of_frequencies, fs, 'power', 'onesided');
        alpha_pow_late(i) = pxx(2);
        disp (['Alpha late ', num2str(i), ' of ', num2str(length(X_late))])
    end

    for i = 1:length(X_middle)
        signal = squeeze(X_middle(i,chan,:));
        [pxx,f] = periodogram(signal,[], number_of_frequencies, fs, 'power', 'onesided');
        alpha_pow_middle(i) = pxx(2);
        disp (['Alpha middle ', num2str(i), ' of ', num2str(length(X_middle))])
    end

    % truncate outliers:
    alpha_pow_early(alpha_pow_early>165) = 165;
    alpha_pow_middle(alpha_pow_middle>165) = 165;

    E = mean(alpha_pow_early);
    M = mean(alpha_pow_middle);
    L = mean(alpha_pow_late);
    
    x = [1 2 3];
    y = [E M L];
    err = [...
        std(alpha_pow_early)/sqrt(length(alpha_pow_early)) ...
        std(alpha_pow_middle)/sqrt(length(alpha_pow_middle)) ...
        std(alpha_pow_late)/sqrt(length(alpha_pow_late))];

%     subplot(1,2,1)
%     plot(alpha_pow_lo)
%     hold on
%     plot(alpha_pow_hi)
%     plot(alpha_pow_mid)
%     tit = title('Alpha power by trial');
%     tit.FontSize = 14;
%     subplot(1,2,2)
    
    if single_mode == 1
        subplot(1,1,1, 'Parent', p)
    else
        subplot(4,3,k, 'Parent', p)
    end
    
    eb = errorbar(x,y,err);
    eb.Parent.XLim = [0 4];
    eb.Parent.XTick = [1 2 3];
    
    eb.Parent.XTickLabel = {'early', 'middle', 'late'};
    eb.Parent.FontSize = 14;
    
    labels = [...
        repmat(1,length(alpha_pow_early),1);...
        repmat(2,length(alpha_pow_middle),1);...
        repmat(3,length(alpha_pow_late),1)...
        ];
    
    dat = [alpha_pow_early; alpha_pow_middle'; alpha_pow_late];
    prob = anova1(dat, labels, 'off');
    
    
    dst = unique({EEG.event.dataset});
    dst(1) = [];
    newStr = erase(dst{k},{'Original file: ', '.eeg'})
    tit_str = {newStr,['p = ', num2str(prob)]};
    tit = title(tit_str);
    tit.FontSize = 14;
    
    
    % dim = [.2 .5 .3 .3];
    % str = {['P1: p = ', num2str(P_P1)], ['N1: p = ', num2str(P_N1)]};
    % % an = annotation(p, 'textbox',dim,'String',str,'FitBoxToText','on');
    % % an.FontSize = 14;
    % annotation(
end