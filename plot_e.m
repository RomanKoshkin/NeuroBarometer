function [ERPx] = plot_e(EEG, ch, tit)

    t = -100:5:295;
    % figure;

    chan = [1:63];
    a = find(ismember({EEG.event.type}, 'one'));
    b = find(ismember({EEG.event.type}, 'two'));
    c = find(ismember({EEG.event.type}, 'three'));
    x = [a b c];

    lats_a = round([EEG.event(a).latency]);
    lats_b = round([EEG.event(b).latency]);
    lats_c = round([EEG.event(c).latency]);
    lats_x = round([EEG.event(x).latency]);

    ERPa = zeros(length(a),length(chan), 80);
    ERPb = zeros(length(b),length(chan), 80);
    ERPc = zeros(length(c),length(chan), 80);
    ERPx = zeros(length(x),length(chan), 80);

    for i = 1:length(a)
        ERPa(i,:,:) = EEG.data(chan, lats_a(i)-20:lats_a(i)+59);
        baseline = mean(ERPa(i,:,1:20),3)';
        ERPa(i,:,:) = squeeze(ERPa(i,:,:)) - baseline;
    end
    se_a = squeeze(std(ERPa,0, 1))/sqrt(size(ERPa,1));
    errorbar(t, squeeze(mean(ERPa(:,ch,:),1)), se_a(ch,:))
    vline(0); hline(0); grid on; hold on

    for i = 1:length(b)
        ERPb(i,:,:) = EEG.data(chan, lats_b(i)-20:lats_b(i)+59);
        baseline = mean(ERPb(i,:,1:20),3)';
        ERPb(i,:,:) = squeeze(ERPb(i,:,:)) - baseline;  
    end
    se_b = squeeze(std(ERPb,0, 1))/sqrt(size(ERPb,1));
    errorbar(t, squeeze(mean(ERPb(:,ch,:),1)), se_b(ch,:))
    vline(0); hline(0); grid on; hold on

    for i = 1:length(c)
        ERPc(i,:,:) = EEG.data(chan, lats_c(i)-20:lats_c(i)+59);
        baseline = mean(ERPc(i,:,1:20),3)';
        ERPc(i,:,:) = squeeze(ERPc(i,:,:)) - baseline; 
    end
    se_c = squeeze(std(ERPc,0, 1))/sqrt(size(ERPc,1));
    errorbar(t, squeeze(mean(ERPc(:,ch,:),1)), se_c(ch,:))
    vline(0); hline(0); grid on; hold on

    for i = 1:length(x)
        ERPx(i,:,:) = EEG.data(chan, lats_x(i)-20:lats_x(i)+59);
        baseline = mean(ERPx(i,:,1:20),3)';
        ERPx(i,:,:) = squeeze(ERPx(i,:,:)) - baseline; 
    end
    se_x = squeeze(std(ERPx,0, 1))/sqrt(size(ERPx,1));
    errorbar(t, squeeze(mean(ERPx(:,ch,:),1)), se_x(ch,:))
    
%     plot(t,mean(ERPx,1), 'LineWidth', 3)
    vline(0); hline(0); grid on; hold off
    legend('440 Hz', '760 Hz', '1990 Hz', 'ALL')
    ax = gca;
    ax.FontSize = 14;
    ax.YLim = [-1.5 1.5];
    ax.XLim = [-100 300];
    title(tit);
end