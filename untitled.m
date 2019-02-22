%%
t = -100:5:295;
chan = 15;

S = struct(...
    'type', {'a', 'a'},...
    'latency', 0,...
    'ISI', 0,...
    'pred', 0,...
    'err', 0);
EV = {EEG.event.type}';
[S(1:length(EV)).type] = EV{:};

y = [EEG.event.latency]';
Y = num2cell(y);
[S(1:length(Y)).latency] = Y{:};

x = diff(y); X = num2cell(x);
[S(2:length(X)).ISI] = X{:};


% subplot(2,1,1)
% plot(x); hold on
d = 3;
pred = 0;
err = 0;
for i = 0:(length(x)-d)
%     c = polyfit([1+i:3+i]',x(1+i:3+i), 1);
%     y_est = polyval(c,1+i:4+i);
%     S(i+4).pred = y_est(4);
    S(i+d).pred = mean([S(1+i:i+d-1).ISI]);
    S(i+d).err = S(i+d).pred - S(i+d).ISI;
%     plot([1+i:4+i],y_est,'r--','LineWidth',2)
end

% subplot(2,1,2)
% % imagesc([0 0 0 err]); colorbar
% plot(4:4+length(err)-1, err)
% ax = gca;
% ax.XLim = [1 length(x)];
% figure;
% % [182:253, 263:324, 334:388, 398:448, 457:516, 527:628, 638:739, 748:840, 849:899, 907:973]
% 
% 
lat_late = round([S([S.err]<-20).latency]');
lat_mid = round([S([S.err]>-20 & [S.err]<20).latency]'); 
lat_early = round([S([S.err]>20).latency]');

ERPlate = zeros(length(lat_late),80);
for i = 1:length(lat_late)
    if lat_late(i) < 21
        continue
    end
    ERPlate(i,:) = EEG.data(chan, lat_late(i)-20:lat_late(i)+59);
    baseline = mean(ERPlate(i,1:20),2);
    ERPlate(i,:) = ERPlate(i,:) - baseline;
end

ERPmid = zeros(length(lat_mid),80);
for i = 1:length(lat_mid)
    if lat_mid(i) < 21
        continue
    end
    ERPmid(i,:) = EEG.data(chan, lat_mid(i)-20:lat_mid(i)+59);
    baseline = mean(ERPmid(i,1:20),2);
    ERPmid(i,:) = ERPmid(i,:) - baseline;
end

ERPearly = zeros(length(lat_early),80);
for i = 1:length(lat_early)
    if lat_early(i) < 21
        continue
    end
    ERPearly(i,:) = EEG.data(chan, lat_early(i)-20:lat_early(i)+59);
    baseline = mean(ERPearly(i,1:20),2);
    ERPearly(i,:) = ERPearly(i,:) - baseline;
end
ERPall = cat(1,ERPearly, ERPmid, ERPlate);
% subplot(1,2,1)
figure
plot(t, mean(ERPlate,1), t, mean(ERPmid,1), t, mean(ERPearly,1)); hold on
plot(t, mean(ERPall,1), 'LineWidth', 3)
vline(0); hline(0); grid on;
leg = legend({
    sprintf('late %2i trials', length(lat_late)),
    sprintf('mid %2i trials', length(lat_mid)),
    sprintf('early %2i trials', length(lat_early))
    sprintf('ALL %2i trials', length(ERPall))
    });
leg.FontSize = 14;