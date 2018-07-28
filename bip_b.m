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