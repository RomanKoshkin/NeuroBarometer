X_third1 = [];
X_third2 = [];
X_third3 = [];

%% ERP by event type (text number):
for i = 1:length({EEG.event.type})
    if isempty(str2num(EEG.event(i).type))==1;
        labels(i) = NaN;
    else
        labels(i) = str2num(EEG.event(i).type);
    end
end

for txt = 1:50
    needed_type = find(ismember(labels, txt));
    qq = quantile(needed_type,[0.33,0.66]);
    third1 = needed_type(find(needed_type<qq(1)));
    third2 = needed_type(find(needed_type>=qq(1) & needed_type<=qq(2)));
    third3 = needed_type(find(needed_type>qq(2)));

    lat_third1 = [EEG.event(third1).latency];
    lat_third2 = [EEG.event(third2).latency];
    lat_third3 = [EEG.event(third3).latency];


    for i = lat_third1
        start = round(i-round(0.1*EEG.srate));
        fin = round(i+round(0.5*EEG.srate));
        X_third1 = cat(3, X_third1, EEG.data(1:63,start:fin));
    end
    
    for i = lat_third2
        start = round(i-round(0.1*EEG.srate));
        fin = round(i+round(0.5*EEG.srate));
        X_third2 = cat(3, X_third2, EEG.data(1:63,start:fin));
    end

    for i = lat_third3
        start = round(i-round(0.1*EEG.srate));
        fin = round(i+round(0.5*EEG.srate));
        X_third3 = cat(3, X_third3, EEG.data(1:63,start:fin));
    end
    disp(txt)
end

%%
a = mean(X_third1,3);
m = mean(X_third2,3);
b = mean(X_third3,3);
plot(t, a(17,:), 'b', t, m(17,:), 'y', t, b(17,:), 'r')
hold on
plot(t, squeeze(mean(X(:,17,:))), 'Color', 'k', 'LineWidth', 2)
grid on
tit = title('Comparison of trials depending on position in the text')
tit.FontSize = 14;
leg = legend('Early (1st third)', 'Middle (2nd third)', 'Late (3rd third)', 'Average')
leg.FontSize = 14;
hline(0)
vline(0)
error('PART I complete')
%%
quant = [0.33 0.66];
cutoff_val = [3 7];
cutoff_val = quantile(scores(var_of_interest,:), quant);
var_of_interest = 4;
chan = 17;

X_third1_m = mean(X_third1, 3);
X_third2_m = mean(X_third2, 3);
X_third3_m = mean(X_third3, 3);
plot(t, X_third1_m(17,:), 'b')
hold on
plot(t, X_third2_m(17,:), 'g')
plot(t, X_third3_m(17,:), 'r')
leg = legend({'early', 'middle', 'late'})
leg.FontSize = 14;
vline(0); hline(0)

LOW = find(scores(var_of_interest,:) <= cutoff_val(1));
HI = find(scores(var_of_interest,:) >= cutoff_val(2));
MID = find(scores(var_of_interest,:) > cutoff_val(1) &...
    scores(var_of_interest,:) < cutoff_val(2));

[Gavg_A, X_low, N1_a] = ERPs(Lb, Ub, EEG, t, 17, LOW, M, 'median');
[Gavg_B, X_mid, N1_b] = ERPs(Lb, Ub, EEG, t, 17, MID, M, 'median');
[Gavg_B, X_high, N1_b] = ERPs(Lb, Ub, EEG, t, 17, HI, M, 'median');
X_low = squeeze(mean(X_low,1));
X_mid = squeeze(mean(X_mid,1));
X_high = squeeze(mean(X_high,1));

D_high_low = X_low - X_mid;

plot(t, X_low(chan,:))
hold on
plot(t, X_high(chan,:))
plot(t, X_mid(chan,:))
plot(t, D_high_low(chan,:), 'LineWidth', 3)
leg = legend({'low', 'high', 'mid', 'diff'});
leg.FontSize = 14;

vline(0); hline(0)

[U,S,~] = svd(D_high_low);


D_third_lo_hi = X_third1_m - X_third3_m;
[U_3rd,S_3rd,~] = svd(D_third_lo_hi);

comp = 1;
figure
subplot(2,2,[1,2])
plot(U(:,comp)); hold on
plot(-U_3rd(:,comp))
tit = title(['Weight values in component', num2str(comp)]);
tit.FontSize = 14;
leg = legend({'High vs. Low scores', 'Early vs. Late Trials Within Ad'});
leg.FontSize = 14;

subplot(2,2,3)
topoplot(U(:,comp), EEG.chanlocs,'style','both','electrodes','labelpoint');
tit = title(['topography of component ', num2str(comp), ' of high scores ERP vs Low scores ERP']);
tit.FontSize = 14;

subplot(2,2,4)
topoplot(-U_3rd(:,comp), EEG.chanlocs,'style','both','electrodes','labelpoint');
tit = title(['topography of component ', num2str(comp), ' of early vs lat ERPs (diff. wave)']);
tit.FontSize = 14;