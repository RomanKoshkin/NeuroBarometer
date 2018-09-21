t = linspace(-100, 500, 121);
ds_ids = unique({EEG.event.dataset})'; ds_ids(1) = [];

for i = 1:length({EEG.event.type})
    if isempty(str2num(EEG.event(i).type))==1;
        labels(i) = NaN;
    else
        labels(i) = str2num(EEG.event(i).type);
    end
end

[EEG.event.third] = deal(0);
for k = 1:length(ds_ids)
    ds_ids(k)
    for txt = 1:50
        tmp_nums = find(ismember({EEG.event.dataset}', ds_ids(k)) & ismember(labels, txt));
        disp(size(tmp_nums))
        qq = quantile(tmp_nums,[0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9]);
        third1 = tmp_nums(find(tmp_nums<qq(1)));
        third2 = tmp_nums(find(tmp_nums>=qq(1) & tmp_nums<=qq(2)));
        third3 = tmp_nums(find(tmp_nums>=qq(2) & tmp_nums<=qq(3)));
        third4 = tmp_nums(find(tmp_nums>=qq(3) & tmp_nums<=qq(4)));
        third5 = tmp_nums(find(tmp_nums>=qq(4) & tmp_nums<=qq(5)));
        third6 = tmp_nums(find(tmp_nums>=qq(5) & tmp_nums<=qq(6)));
        third7 = tmp_nums(find(tmp_nums>=qq(6) & tmp_nums<=qq(7)));
        third8 = tmp_nums(find(tmp_nums>=qq(7) & tmp_nums<=qq(8)));
        third9 = tmp_nums(find(tmp_nums>=qq(8) & tmp_nums<=qq(9)));
        third10 = tmp_nums(find(tmp_nums>qq(9)));
        
        [EEG.event(third1).third] = deal(1);
        [EEG.event(third2).third] = deal(2);
        [EEG.event(third3).third] = deal(3);
        [EEG.event(third4).third] = deal(4);
        [EEG.event(third5).third] = deal(5);
        [EEG.event(third6).third] = deal(6);
        [EEG.event(third7).third] = deal(7);
        [EEG.event(third8).third] = deal(8);
        [EEG.event(third9).third] = deal(9);
        [EEG.event(third10).third] = deal(10);
    end
end

chan = 17;
low_bound = 130;
up_bound = 170;

cumm = [];
labs = [];
mu = [];
for i = 1:10
    idx = find([EEG.event.third]==i);
    lat = [EEG.event(idx).latency];
    X = ERPs_1(EEG, lat);
    dps = mean(X(:,chan,find(t==low_bound):find(t==up_bound)),3);
    mu(i) = mean(dps);
    cumm = cat(1, cumm, dps);
    labs = cat(1, labs, ones(length(dps),1) * i);
end

mu = [];
se = [];
for i = 1:10
    mu(i) = mean(cumm(find(ismember(labs,i))));
    se(i) = std(cumm(find(ismember(labs,i))))/sqrt(length(cumm(find(ismember(labs,i)))));
end

mdl = fitlm(1:10, mu);
ss = mdl.Coefficients.Estimate;
slope = ss(2);
intercept = ss(1);
f = @(x) slope*x + intercept;
ezplot(f, 0, 11)
hold on

eb = errorbar(1:10, mu, se);
eb.Parent.XLim = [0 11];
eb.Parent.XTick = [1:10];

eb.Parent.XTickLabel = {'Q1', 'Q2', 'Q3', 'Q4', 'Q5', 'Q6', 'Q7', 'Q8', 'Q9', 'Q10'};
eb.Parent.FontSize = 14;
eb.Parent.YLim = [-0.9 0];
eb.Parent.XLabel.String = 'Quantiles';
eb.Parent.YLabel.String = 'Voltage, \muV';
eb.Parent.Title.String = 'N1 amplitude';
