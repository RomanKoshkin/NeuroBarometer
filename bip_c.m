cd /Users/RomanKoshkin/Documents/MATLAB/NeuroBarometer
eeglab redraw
load('a.mat')
load('scores.mat')
load('lookup_tab.mat')
% EEG = pop_loadset('filepath', '/Volumes/Transcend/NeuroBarometer/beeps_1/', 'filename', '1-6.set');
EEG = pop_loadset('filepath', '/Volumes/Transcend/NeuroBarometer/beeps_1/', 'filename', 'all.mat');
%% load responses to the EEG.event struct. 
% if you want projected scores, run the section below

% [EEG.event.dataset] = deal([]);
% [EEG.event.dataset] = deal(EEG.comments);


% perform some string transformation (dataset names):
for i = 1:length({EEG.event.dataset})
    EEG.event(i).dataset = erase(EEG.event(i).dataset, 'Original file: ');
    EEG.event(i).dataset = erase(EEG.event(i).dataset, '.eeg');
end


% enter score file names for each epoch:
clc
for i = 1:length({EEG.event.dataset})
    ds_name = EEG.event(i).dataset;
    if strcmp(ds_name, '') == 0
        ds_find_idx = find(ismember({lookup_tab{:,1}}, ds_name));
        EEG.event(i).sc = lookup_tab{ds_find_idx,2};
    else
%         disp(i)
    end
end

% add responses for each epoch:

for i = 1:length({EEG.event.dataset})
    if      (strcmp(EEG.event(i).type, 'boundary') == 1 ||...
            strcmp(EEG.event(i).type, 'Nachalo audio') == 1 ||...
            strcmp(EEG.event(i).type, 'a') == 1 ||...
            strcmp(EEG.event(i).type, 'empty') == 1 ||...
            strcmp(EEG.event(i).type, 'A') == 1 ||...
            strcmp(EEG.event(i).type, 'Bip') == 1) == 0
        EEG.event(i).response1 = eval([EEG.event(i).sc, '(1,', EEG.event(i).type, ')']);
        EEG.event(i).response1 = eval([EEG.event(i).sc, '(:,', EEG.event(i).type, ')']);
    else
        EEG.event(i).response1 = nan(10,1);
    end
end

%% by-subject plots:
% load('scores.mat')
% lo_co = 3;
% hi_co = 5;

% if you want projected scores and quantiles, launch scores_eig and BLOCK_2

quant = [0.25 0.75];
var_of_interest = 2;

ff = figure('units','normalized','outerposition',[0 0 1 1]);
pp = uipanel('Parent',ff,'BorderType','none');


ds_ids = unique({EEG.event.dataset})'; ds_ids(1) = [];
responses = [EEG.event.response1]';
for k = 1:11%length(ds_ids)
    ds_of_interest = k;
    
    ds_idx_tmp = ismember({EEG.event.dataset}, ds_ids(ds_of_interest));
    
    lo_co = quantile(responses(ds_idx_tmp, var_of_interest), quant(1));
    hi_co = quantile(responses(ds_idx_tmp, var_of_interest), quant(2));
    
    LO_idx = (responses(:,var_of_interest) <= lo_co)' & ds_idx_tmp;
    HI_idx = (responses(:,var_of_interest) >= hi_co)' & ds_idx_tmp;
   
    set(0, 'CurrentFigure', ff)

    subplot(3,4,k, 'Parent', pp)
    histogram(responses(LO_idx, var_of_interest))
    hold on
    histogram(responses(HI_idx, var_of_interest)) 
    vline(lo_co); vline(hi_co);
    tit = title({'LO & HI', [max(responses(LO_idx, var_of_interest)) min(responses(HI_idx, var_of_interest))]}); tit.FontSize = 14;
   
    % check if all is correct:
%     chk = cell2mat({EEG.event(HI_idx).response1});
%     unique(chk(var_of_interest,:))

    % LO_idx = find(responses(:,var_of_interest) <= lo_co);
    % HI_idx = find(responses(:,var_of_interest) >= hi_co);

    lat_lo = [EEG.event(LO_idx).latency];
    lat_hi = [EEG.event(HI_idx).latency];

    X_lo = ERPs_1(EEG, lat_lo);
    X_hi = ERPs_1(EEG, lat_hi);

    X_lo_GA = squeeze(mean(X_lo,1));
    X_hi_GA = squeeze(mean(X_hi,1));

    X_d_GA = X_hi_GA - X_lo_GA;
    [U,S,V] = svd(X_d_GA);

    f = figure('units','normalized','outerposition',[0 0 1 1]);
    p = uipanel('Parent',f,'BorderType','none'); 
    if length(ds_ids(ds_of_interest)) > 1
        p.Title = 'all ';
    else
        p.Title = ds_ids(ds_of_interest); 
    end
    p.TitlePosition = 'centertop'; 
    p.FontSize = 14;
    p.FontWeight = 'bold';

    for i = 1:3
        subplot(3,4,9+i,'Parent',p)
        topoplot(U(:,i), EEG.chanlocs,'style','both','electrodes','labelpoint');
        tit = title(['Comp. ', num2str(i), ' DW (hi-lo sc.)']);
        tit.FontSize = 14;
    end
    
    subplot(3,4,9)
    imagesc(X_d_GA*X_d_GA');
    tit = title('cov of D_wave (<3 vs >7) topos');
    tit.FontSize = 14;

    [U,S,V] = svd(squeeze(mean(X_lo,1)));
    subplot(3,4,[3],'Parent',p)
    topoplot(U(:,1), EEG.chanlocs,'style','both','electrodes','labelpoint');
    tit = title('Topographies of lowly scored trials');
    tit.FontSize = 14;
    subplot(3,4,[4],'Parent',p)
    plot(U(:,1)'*squeeze(mean(X_lo,1)))
    tit = title('Projection of data on comp.1');
    tit.FontSize = 14;


    [U,S,V] = svd(squeeze(mean(X_hi,1)));
    subplot(3,4,[7],'Parent',p)
    topoplot(U(:,1), EEG.chanlocs,'style','both','electrodes','labelpoint');
    tit = title('Topographies of highly scored trials');
    tit.FontSize = 14;
    subplot(3,4,[8],'Parent',p)
    plot(U(:,1)'*squeeze(mean(X_hi,1)))
    tit = title('Projection of data on comp.1');
    tit.FontSize = 14;


    subplot(3,4,[1,2,5,6],'Parent',p)
    t = linspace(-100, 500, 121);
    plot(t, squeeze(mean(X_lo(:,17,:),1)))
    hold on
    plot(t, squeeze(mean(X_hi(:,17,:),1)))
    tit = title(a(var_of_interest));
    tit.FontSize = 14;
    leg = legend({'low scores', 'high scores'});
    leg.FontSize = 14;
    vline(0);hline(0);grid on
end
error('CODE STOPPED')

%% Grand Averages
chan = 17;

f = figure('units','normalized','outerposition',[0 0 1 1]);
p = uipanel('Parent',f,'BorderType','none'); 
p.Title = 'Grand Averages (high vs. low scores)'; 
p.TitlePosition = 'centertop'; 
p.FontSize = 20;    
p.FontWeight = 'bold';

f1 = figure('units','normalized','outerposition',[0 0 1 1]);
p1 = uipanel('Parent',f1,'BorderType','none'); 
p1.Title = 'Alpha on Grand Average'; 
p1.TitlePosition = 'centertop'; 
p1.FontSize = 20;    
p1.FontWeight = 'bold';

% to use projected scores, run SCORES_EIG.m first then run BLOCK_2
% otherwise load('scores.mat')

responses = [EEG.event.response1]';
tab = struct;

for k = 1:10
    quant = [0.25 0.75];
    var_of_interest = k;


% %     lo_co = 4;
% %     hi_co = 8;
   
    lo_co = quantile(responses(:, var_of_interest), quant(1));
    hi_co = quantile(responses(:, var_of_interest), quant(2));
    
    LO_idx = find(responses(:,var_of_interest) <= lo_co);
    HI_idx = find(responses(:,var_of_interest) >= hi_co);
    MID_idx = find(not(responses(:,var_of_interest) <= lo_co) &...
        not(responses(:,var_of_interest) >= hi_co));
    
    EEG.event(LO_idx).resp = deal('low');
    EEG.event(MID_idx).resp = deal('mid');
    EEG.event(HI_idx).resp = deal('high');

    lat_lo = [EEG.event(LO_idx).latency];
    lat_hi = [EEG.event(HI_idx).latency];
    lat_mid = [EEG.event(MID_idx).latency];

    X_lo = ERPs_1(EEG, lat_lo);
    X_hi = ERPs_1(EEG, lat_hi);
    X_mid = ERPs_1(EEG, lat_mid);

    X_lo_GA = squeeze(mean(X_lo,1));
    X_hi_GA = squeeze(mean(X_hi,1));
    X_mid_GA = squeeze(mean(X_mid,1));

    %%%%%%%%%%%%%%%%%%%%%%%%
    % plot topographies of the ERP components
    %%%%%%%%%%%%%%%%%%%%%%%%
    
    X_d_GA = X_hi_GA - X_lo_GA;
    [U,S,V] = svd(X_d_GA);
    
    figure
    subplot(1,3,1)
    imagesc(X_d_GA*X_d_GA');
    tit = title('cov of D_wave (<3 vs >7) topos');
    tit.FontSize = 14;
    
    [U,S,V] = svd(squeeze(mean(X_lo,1)));
    subplot(1,3,2)
    topoplot(U(:,1), EEG.chanlocs,'style','both','electrodes','labelpoint');
    tit = title('Topographies of lowly scored trials');
    tit.FontSize = 14;
    
    [U,S,V] = svd(squeeze(mean(X_hi,1)));
    subplot(1,3,3)
    topoplot(U(:,1), EEG.chanlocs,'style','both','electrodes','labelpoint');
    tit = title('Topographies of highly scored trials');
    tit.FontSize = 14;
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % END TOPOGRAPHIES
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%     subplot(4,3,k, 'Parent', p)
    t = linspace(-100, 500, 121);
    set(0, 'CurrentFigure', f)
    [tab] = plot_single_stat(X_lo_GA, X_hi_GA, X_lo, X_hi, t, k, p, tab, chan, 0);
%     plot(t, X_lo_GA(17,:))
% %     avg_amp(X_lo_GA, 17, t, [100 150])
%     hold on
%     plot(t, X_hi_GA(17,:))
    tit = title(a(var_of_interest));
    tit.FontSize = 11;
    leg = legend({'low scores', 'high scores'});
    leg.FontSize = 14;
    
    set(0, 'CurrentFigure', f1)
    get_alpha(EEG, X_lo, X_hi, X_mid, k, p1, a, chan, 0);
    
end

%%
load('scores.mat')
R = cat(2, scores_4july,scores_5july,scores_6july,scores_7july,scores_9july,scores_10august);
[U,S,V] = svd(R);
scores_4july = U' * scores_4july;
scores_5july = U' * scores_5july;
scores_6july = U' * scores_6july;
scores_7july = U' * scores_7july;
scores_9july = U' * scores_9july;
scores_10august = U' * scores_10august;

for i = 1:length({EEG.event.dataset})
    if      (strcmp(EEG.event(i).type, 'boundary') == 1 ||...
            strcmp(EEG.event(i).type, 'Nachalo audio') == 1 ||...
            strcmp(EEG.event(i).type, 'a') == 1 ||...
            strcmp(EEG.event(i).type, 'A') == 1 ||...
            strcmp(EEG.event(i).type, 'Bip') == 1) == 0
        EEG.event(i).response1 = eval([EEG.event(i).sc, '(1,', EEG.event(i).type, ')']);
        EEG.event(i).response1 = eval([EEG.event(i).sc, '(:,', EEG.event(i).type, ')']);
    else
        EEG.event(i).response1 = nan(10,1);
    end
end

for i = 1:length({EEG.event.dataset})
    EEG.event(i).response1 = mapminmax(EEG.event(i).response1',1,10);
end

responses = cell2mat({EEG.event.response1}');
lo_co = 3;
hi_co = 7;
var_of_interest = 3;

LO_idx = find(responses(:,var_of_interest) <= lo_co);
HI_idx = find(responses(:,var_of_interest) >= hi_co);

lat_lo = [EEG.event(LO_idx).latency];
lat_hi = [EEG.event(HI_idx).latency];

X_lo = ERPs_1(EEG, lat_lo);
X_hi = ERPs_1(EEG, lat_hi);

figure
[U,S,V] = svd(squeeze(mean(X_lo,1)));
subplot(221)
topoplot(U(:,1), EEG.chanlocs,'style','both','electrodes','labelpoint');
subplot(222)
plot(U(:,1)'*squeeze(mean(X_lo,1)))

[U,S,V] = svd(squeeze(mean(X_hi,1)));
subplot(223)
topoplot(U(:,1), EEG.chanlocs,'style','both','electrodes','labelpoint');
subplot(224)
plot(U(:,1)'*squeeze(mean(X_hi,1)))

t = linspace(-100, 500, 121);

figure
plot(t, squeeze(mean(X_lo(:,17,:),1)))
hold on
plot(t, squeeze(mean(X_hi(:,17,:),1)))
tit = title(a(var_of_interest));
tit.FontSize = 14;
leg = legend({'low scores', 'high scores'});
leg.FontSize = 14;
vline(0);hline(0);grid on

%% PROJECT THE SCORES:

eig_of_interest = 2;
g = [];
scores_tmp = [];
U = [];
all_scores = [];
for i = 1:11
    scores_tmp = eval(lookup_tab{i,2});
    all_scores = cat(2, all_scores, scores_tmp);
    [U(:,:,i),~,~] = svd(scores_tmp);
end

% fix the eigs:
flip_eigs = [1, 2, 3, 4, 5, 6];
U(:,:,flip_eigs) = U(:,:,flip_eigs) * (-1);

U_m = squeeze(mean(U,3));

figure
for i = 1:11
    subplot(3,4,i)
    imagesc(squeeze(U(:,:,i))); colorbar;
end

U_m = U_m * (-1);
subplot(3,4,12)
imagesc(U_m); colorbar
tit = title('Avarage eigenvectors');
tit.FontSize = 14;

% project and normalize the scores:
sc = mapminmax(U_m'* all_scores, 0,1);
qq = quantile(sc, [0.33 0.66]);

figure
dsp = 0;
for i = 1:11
    sc_tmp = sc(:,1+dsp:50+dsp);
    assignin('base', lookup_tab{i,2}, sc_tmp);
    subplot(3,4,i)
    histogram(sc_tmp); 
    tit = title(num2str(i));
    tit.FontSize = 14;
    dsp = dsp + 50;
end