% % EEG = pop_loadset('filepath', '/Volumes/Transcend/10_ads/','filename', 'ten_subj_ica.set');
EEG = pop_loadset('filepath', '/Volumes/Transcend/10_ads/','filename', 'fourteen_subj_ica.set');
%%
clc 
% elect_subj = {'Vovk', 'Indyukova', 'Buyanova', 'Deryabin', 'Kabanov', 'Kabanova', 'Sukhanova', 'Vishnyakova', 'Karpinskaya', 'Orlichenya'};
elect_subj = {'Deryabin', 'Kabanov', 'Kabanova', 'Sukhanova', 'Vishnyakova', 'Karpinskaya', 'Orlichenya'};
ads =       [3    14    15    19    23    24    25    30    39    47];
suppress_ERP = 0;          % suppress ERPs or not
zero_mean_unit_var = 0;    % trasform the scores to zero mean and unit variance or not
collect_data_for_XGBoost = 0; % dump data for Xtreme Gradient Boost or not
plotgraphs = 0             % plot graphs
truncate_bands = 1         % the srate is 200 Hz so Nyquist is 100, we only need 0-40 passband
passband_cap = 40          % in HERZ !!!!!!!
MaxNumSplits = 8           % max num of splits in a DT
number_of_frequencies = 50 % N of frequency bins (best = 50)
ChannelsOfInterest = 15;   %[15 17 20 22]; %15
QuestionsOfInterest = 2    %[1:10];
n_test = 1;                % leave 1 out 2 out
boosting = 0;
fprintf('Number of test combinations: %i', factorial(10)/(factorial(n_test)*factorial(10-n_test)))
comb = combnk(1:10, n_test);
%%

if suppress_ERP==1;
    disp('\nsuppressing ERPs')
    sigma = 0.028;
    mu = 0.12;
    fs = 200;
    lo = -0.1;
    hi = 0.3;
    fs = 200;
    gw = gausswin(fs, lo, hi, sigma, mu);
    EEG = supressERP(EEG, gw);
end

varNames = {'test_ad', 'quest', 'across_subj_corr', 'stron_pr', 'runtime', 'chan', 'GT', 'pred', 'r', 'MSE'};
tmpvar = zeros(1, n_test);
tab = table([tmpvar; tmpvar], [0; 0], [0; 0], [0; 0], [0; 0], [0; 0], [0; 0], [0; 0], [0; 0], [0; 0], 'VariableNames',varNames);
warning('off', 'MATLAB:table:RowsAddedExistingVars')
c = 0;

XX_train = zeros(32, 10, size(comb, 1), 63, 11);
XX_test = zeros(32, 10, size(comb, 1), 7, 11);
zz_train = zeros(32, 10, size(comb, 1), 63, 1);
zz_test = zeros(32, 10, size(comb, 1), 7, 1);

for chan = ChannelsOfInterest
    for quest = QuestionsOfInterest
        for i = 1:size(comb, 1)
            c = c + 1;
            tic
            test_ads = ads(comb(i,:));
            train_ads = ads(~ismember(ads, test_ads));

            [X_train, f, z_train, ad_train] = get_set(EEG, train_ads, quest, chan, zero_mean_unit_var, number_of_frequencies, elect_subj);
            [X_test, f, z_test, ad_test] = get_set(EEG, test_ads, quest, chan, zero_mean_unit_var, number_of_frequencies, elect_subj);

            [~,loc] = min(abs(f-passband_cap));

            if truncate_bands==1
                X_train = X_train(:,1:loc);
                X_test = X_test(:,1:loc);
            end
            
            if collect_data_for_XGBoost==1
                XX_train(chan,quest,i,:,:) = X_train;
                XX_test(chan,quest,i,:,:) = X_test;
                zz_train(chan,quest,i,:) = z_train;
                zz_test(chan,quest,i,:) = z_test;
                fprintf('Chan: %i, quest %i, ad %i \n', chan, quest, test_ads)
            end
            
            if collect_data_for_XGBoost==0
                if boosting==1
                    Mdl = fitrensemble(X_train, z_train,...
                        'Method','Bag',... # Bag works better than LSboost
                        'NumLearningCycles', 30,...
                        'Learners','Tree');
                else
                Mdl = fitrtree(X_train, z_train, 'MaxNumSplits', MaxNumSplits);
                if plotgraphs==1
                    view(Mdl,'Mode','graph')
                end
                end
                pred = predict(Mdl, X_test);
                if n_test==2
                    fprintf('R on test ads %i %i is %.4f', test_ads, corr(pred, z_test))
                else
                    fprintf('Chan: %i, quest %i, R on test ad %i is %.4f\n', chan, quest, test_ads, corr(pred, z_test))
                end

                tab.test_ad(c, :) = test_ads;
                if boosting==0
                    Str = Mdl.CutPredictor{1};
                    Str(strfind(Str, 'x')) = [];
                    tab.stron_pr(c,:) = str2num(Str);
                end
                tab.quest(c, :) = quest;
                tab.chan(c) = chan;
                tab.across_subj_corr(c) = corr(pred, z_test);
                tab.GT(c) = mean(z_test);
                tab.pred(c) = mean(pred);
                if isnan(tab.across_subj_corr(c))==1
                    disp([num2str(quest), ' ', num2str(test_ads)])
                end
                tab.runtime(c) = toc;
            end
        end
    end
end
tab.MSE(c) = sum((tab.GT - tab.pred).^2);
tab.r(c) = corr(tab.GT, tab.pred);

% if we make data for XGBoost, dump it to XGB.mat:
if collect_data_for_XGBoost==1
    save('/Users/RomanKoshkin/Downloads/XGB.mat', 'XX_train', 'XX_test', 'zz_train', 'zz_test');
end

% dump results and plot stuff
if boosting==1
    writetable(tab,'/Users/RomanKoshkin/Downloads/DTboost.csv','Delimiter',',')
    rsLoss = resubLoss(Mdl,'Mode','Cumulative');
    figure; plot(rsLoss)
else
    % fix those cases where the model failed to find a good fit:
    tab.across_subj_corr(isnan(tab.across_subj_corr)) = 0;
    writetable(tab,'/Users/RomanKoshkin/Downloads/DT.csv','Delimiter',',')
%     genError = kfoldLoss(Mdl,'Mode','Cumulative');
%     figure; plot(genError)
end
    
warning('on', 'MATLAB:table:RowsAddedExistingVars')
%% plot the topographies of accuracy (run only if you set chans = 1:32)
% this takes ages, so run it on the server
if ChannelsOfInterest==1:32
    x = readtable('/Users/RomanKoshkin/Downloads/DTboost (2).csv');
    figure
    for quest = 1:10
        X = zeros(32,1);
        for chan = 1:32
            X(chan) = mean(x.corr(ismember([x.quest], quest) & ismember([x.chan], chan)));
        end
        Max = max(X);
        Min = min(X);
        X = X-mean(X);

        subplot(2,5,quest)
        topoplot(X, EEG.chanlocs,...
            'style','both',...
            'electrodes','labelpoint');
        cbar('vert', 0, [Min Max]);
        title(['Question ', num2str(quest)])
    end
end
%%

function [PXX, f, z, ad] = get_set(...
    EEG, ads, quest, chan, zero_mean_unit_var, number_of_frequencies, elect_subj)
    PXX = [];
    z = 0;
    c = 0;
    ad = [];
    for i = ads
        for s = elect_subj
            c = c + 1;
            x = find(ismember([EEG.event.code], i) & ismember({EEG.event.subj}, s));
            xx = EEG.data(:, round(EEG.event(min(x)).latency):round(EEG.event(max(x)).latency));
            [pxx,f] = periodogram(xx(chan,:),[], number_of_frequencies, EEG.srate, 'power', 'onesided');
            PXX = cat(1, PXX, pxx');
            z(c) = EEG.event(min(x)+1).score(quest);
            ad(c,1) = i;
        end
    end
    % center the z and scale to unit variance:
    if zero_mean_unit_var==1
        z = ((z-mean(z(:)))./std(z(:)))';
    end
    z = z';
end
