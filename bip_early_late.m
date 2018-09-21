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
        tmp_nums = find(ismember({EEG.event.dataset}, ds_ids(k)) & ismember(labels, txt));
        qq = quantile(tmp_nums,[0.25,0.75]);
        third1 = tmp_nums(find(tmp_nums<qq(1)));
        third2 = tmp_nums(find(tmp_nums>=qq(1) & tmp_nums<=qq(2)));
        third3 = tmp_nums(find(tmp_nums>qq(2)));
        
        [EEG.event(third1).third] = deal(1);
        [EEG.event(third2).third] = deal(2);
        [EEG.event(third3).third] = deal(3);
    end
end

%%
f2 = figure('units','normalized','outerposition',[0 0 1 1]);
p2 = uipanel('Parent',f2,'BorderType','none');
p2.Title = 'Alpha Power (Early, Middle, Late)'; p2.TitlePosition = 'centertop'; p2.FontSize = 20; p2.FontWeight = 'bold';

f = figure('units','normalized','outerposition',[0 0 1 1]);
p = uipanel('Parent',f,'BorderType','none');
p.Title = 'Average ERPs (Early, Middle, Late)'; p.TitlePosition = 'centertop'; p.FontSize = 20; p.FontWeight = 'bold';

ff = figure('units','normalized','outerposition',[0 0 1 1]);
s = uipanel('Parent',ff,'BorderType','none');
s.Title = 'Difference Topographies'; s.TitlePosition = 'centertop'; s.FontSize = 20; s.FontWeight = 'bold';

f_early = figure('units','normalized','outerposition',[0 0 1 1]);
s_early = uipanel('Parent',f_early,'BorderType','none');
s_early.Title = 'Early Topographies'; s_early.TitlePosition = 'centertop'; s_early.FontSize = 20; s_early.FontWeight = 'bold';

f_late = figure('units','normalized','outerposition',[0 0 1 1]);
s_late = uipanel('Parent',f_late,'BorderType','none');
s_late.Title = 'Late Topographies'; s_late.TitlePosition = 'centertop'; s_late.FontSize = 20; s_late.FontWeight = 'bold';

f_cov = figure('units','normalized','outerposition',[0 0 1 1]);
s_cov = uipanel('Parent',f_cov,'BorderType','none');
s_cov.Title = 'Covariance of Early vs. Late Trials'; s_cov.TitlePosition = 'centertop'; s_cov.FontSize = 20; s_cov.FontWeight = 'bold';

for i = 1:11
    early_idx = find([EEG.event.third]==1 & ismember({EEG.event.dataset}, ds_ids(i)));
    middle_idx = find([EEG.event.third]==2 & ismember({EEG.event.dataset}, ds_ids(i)));
    late_idx = find([EEG.event.third]==3 & ismember({EEG.event.dataset}, ds_ids(i)));

    lat_early = [EEG.event(early_idx).latency];
    lat_middle = [EEG.event(middle_idx).latency];
    lat_late = [EEG.event(late_idx).latency];

    X_early = ERPs_1(EEG, lat_early);
    X_middle = ERPs_1(EEG, lat_middle);
    X_late = ERPs_1(EEG, lat_late);

    X_early_m = squeeze(mean(X_early,1));
    X_middle_m = squeeze(mean(X_middle,1));
    X_late_m = squeeze(mean(X_late,1));
    
    set(0, 'CurrentFigure', f2)
    get_alpha_EML(EEG, X_early, X_late, X_middle, i, p2, a, 17, 0)
    
    X_d = X_early_m - X_late_m;
    [U, S, V] = svd(X_d);
    set(0, 'CurrentFigure', ff)
    subplot(3,4,i, 'Parent', s)
    topoplot(U(:,1), EEG.chanlocs,'style','both','electrodes','labelpoint');
    tit = title(ds_ids(i));
    tit.FontSize = 14;
    
    [U, S, V] = svd(X_early_m);
    set(0, 'CurrentFigure', f_early)
    subplot(3,4,i, 'Parent', s_early)
    topoplot(U(:,1), EEG.chanlocs,'style','both','electrodes','labelpoint');
    tit = title(ds_ids(i));
    tit.FontSize = 14;
    
    [U, S, V] = svd(X_late_m);
    set(0, 'CurrentFigure', f_late)
    subplot(3,4,i, 'Parent', s_late)
    topoplot(U(:,1), EEG.chanlocs,'style','both','electrodes','labelpoint');
    tit = title(ds_ids(i));
    tit.FontSize = 14;
    
    set(0, 'CurrentFigure', f)
    subplot(3,4,i, 'Parent', p)
    plot(t, X_early_m(17,:), t, X_middle_m(17,:), t, X_late_m(17,:))
    tit = title(ds_ids(i));
    tit.FontSize = 14;
    
    set(0, 'CurrentFigure', f_cov)
    subplot(3,4,i, 'Parent', s_cov)
    imagesc(X_d * X_d')
    tit = title(ds_ids(i));
    tit.FontSize = 14;
end
%%
early_idx = find([EEG.event.third]==1 & ismember({EEG.event.dataset}, ds_ids([1:11])));
middle_idx = find([EEG.event.third]==2 & ismember({EEG.event.dataset}, ds_ids([1:11])));
late_idx = find([EEG.event.third]==3 & ismember({EEG.event.dataset}, ds_ids([1:11])));

lat_early = [EEG.event(early_idx).latency];
lat_middle = [EEG.event(middle_idx).latency];
lat_late = [EEG.event(late_idx).latency];

X_early = ERPs_1(EEG, lat_early);
X_middle = ERPs_1(EEG, lat_middle);
X_late = ERPs_1(EEG, lat_late);

X_early_m = squeeze(mean(X_early,1));
X_middle_m = squeeze(mean(X_middle,1));
X_late_m = squeeze(mean(X_late,1));

chan = 17;
low_bound = 130;
up_bound = 170;
early_dps = mean(X_early(:,chan,find(t==low_bound):find(t==up_bound)),3);
middle_dps = mean(X_middle(:,chan,find(t==low_bound):find(t==up_bound)),3);
late_dps = mean(X_late(:,chan,find(t==low_bound):find(t==up_bound)),3);
labels = [...
        repmat(1,length(early_dps),1);...
        repmat(2,length(middle_dps),1);...
        repmat(3,length(late_dps),1)...
        ];
dat = [early_dps; middle_dps; late_dps];
prob = anova1(dat, labels, 'off')

% X_d = X_early_m - X_late_m;
% [U, S, V] = svd(X_d);
% 
% subplot(1,3,1)
% topoplot(U(:,1), EEG.chanlocs,'style','both','electrodes','labelpoint');
% tit = title('Grand Average');
% tit.FontSize = 14;

f2 = figure('units','normalized','outerposition',[0 0 1 1]);
p2 = uipanel('Parent',f2,'BorderType','none');
p2.Title = 'Alpha Power (Early, Middle, Late)'; p2.TitlePosition = 'centertop'; p2.FontSize = 20; p2.FontWeight = 'bold';
get_alpha_EML(EEG, X_early, X_late, X_middle, 1, p2, a, 17, 1)

figure
plot(t, X_early_m(17,:), 'b')
hold on
plot(t, X_middle_m(17,:), 'y')
plot(t, X_late_m(17,:), 'r')
tit = title({'Grand Average', ['p = ', num2str(prob)]});
tit.FontSize = 14;
leg = legend({'early', 'middle', 'late'});
leg.FontSize = 14;
box off
vline(0); hline(0)
ax = gca;
S = struct;
S.Vertices = [low_bound ax.YLim(1); low_bound ax.YLim(2); up_bound ax.YLim(2); up_bound ax.YLim(1)];
S.Faces = [1 2 3 4];
S.EdgeColor = 'none';
S.FaceAlpha = 0.25;
patch(S)