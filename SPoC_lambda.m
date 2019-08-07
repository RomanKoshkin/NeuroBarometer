%% 1 Get test & train data tensors and labels
cd('/Users/RomanKoshkin/Documents/MATLAB/NeuroBarometer')
clear
clc
% passband = [[0 0]; [33 40]; [29 36]; [26 31]; [20 28]; [15 22]; [10 17]; [6 12]; [3 8]; [1 5]];
load('passband.mat'); disp(passband)


adaboost = 1
silent = 1;

% build_datasets(passband);

fileID = fopen('exptable.txt','w'); % this is where we'll dump data
load('a.mat')

ads =       [3    14    15    19    23    24    25    30    39    47];
n_test = 2; % number of test ads

disp(sprintf('Number of test ad combinations: %i', factorial(10)/(factorial(n_test)*factorial(10-n_test))))
comb = combnk(1:10, n_test);
varNames = {'test_ads','corr','runtime'};
tmpvar = zeros(1, n_test);
tab = table([tmpvar; tmpvar], [0; 0], [0; 0], 'VariableNames',varNames);
warning('off', 'MATLAB:table:RowsAddedExistingVars')

%%
for quest = 2 %1:10
    for i = 1:size(comb, 1) 
%         train_ads = ads;
%         train_ads(k) = [];
%         test_ads = ads(k);
        
        test_ads = ads(comb(i,:));
        train_ads = ads(~ismember(ads, test_ads));
        
        disp(['train_ads:' num2str(train_ads)])
        disp(['test_ads:' num2str(test_ads)])
        elect_subj = {'Deryabin', 'Kabanov', 'Kabanova', 'Sukhanova', 'Vishnyakova', 'Karpinskaya', 'Orlichenya'};

        if adaboost==1
            n_st = length(passband);
            WW = zeros(n_st,32,32);
            AA = zeros(n_st,32,32);
            
            % TRAINING ENSEMBLE MODELS:
            for st = 1:n_st
                EEG = pop_loadset(...
                'filepath', '/Volumes/Transcend/10_ads/ensemble_data/',...
                'filename', ['dat_', num2str(st), '.set']);
                
                if st==1
                    % the first time we just take all the original samples without resampling:
                    [C, C_z, C_beau, z_train, ad] = get_cov_z(EEG, train_ads, elect_subj, quest);
                else
                    samp_wts = abs(resid)/sum(abs(resid));
                    new_samp_idx = randsample(1:length(samp_wts), length(samp_wts), true, samp_wts);
                    [C, C_z, C_beau, z_train, ad] = resample_data(EEG, train_ads, elect_subj, quest, new_samp_idx);
                end
                [C_z_white, M] = get_white_C_z(C_beau, C_z);
                [W, A] = spoc_l(C_z_white, M, C_beau);
                [r_train, z_tilde_train, resid] = evaluate_model(W, C_z, C, C_beau, z_train);
    %             if W(15,1) > 0
    %                 W = -W;
    %                 disp('negative')
    %             end
                WW(st,:,:) = W;
                AA(st,:,:) = A;
            end
            
            % TESTING ENSEMBLE MODELS:
            if ~exist('r_test')
                r_test = zeros(1, n_st);
                z_tilde_test = zeros(length(resid), n_st);
                z_test = zeros(length(resid), n_st);
            end
            
            for st = 1:n_st
                
                EEG = pop_loadset(...
                'filepath', '/Volumes/Transcend/10_ads/ensemble_data/',...
                'filename', ['dat_', num2str(st), '.set']);
            
                [r_test, z_tilde_test, z_test] = test_model(squeeze(WW(st,:,:)), EEG, test_ads, elect_subj, quest);
                if ~exist('r_test_acc')==1
                    r_test_acc = zeros(1, n_st);
                    z_tilde_test_acc = zeros(length(z_test), n_st);
                    z_test_acc = zeros(length(z_test), n_st);
                    model_wts = zeros(1, n_st);
                end
                r_test_acc(st) = r_test; 
                z_tilde_test_acc(:,st) = z_tilde_test;
                z_test_acc(:,st) = z_test;
                model_wts(st) = sumsqr(z_test - z_tilde_test);
            end
            % norm model weights by the sum of all the model errors:
            % and make sure they sum to 1.
            model_wts = model_wts/sum(model_wts);
            mw1 = -(model_wts - mean(model_wts)) + mean(model_wts);
            mw2 = mapminmax(mw1, 0, 1); mw2 = mw2/sum(mw2);

            final_accuracy = corr(mean(z_tilde_test_acc*mw2', 2), z_test);
            fprintf(fileID, sprintf('%s %i %.4f \n', num2str(test_ads), quest, final_accuracy));


            R = zeros(1, size(WW,1));
            for i = 1:size(WW,1)
                R(i) = corr(z_test, z_tilde_test_acc(:,i));
            end

            if silent==0
                % plot models' performance and their respective weights:
                figure
                pb_lab = arrayfun(@(x) char(num2str(x)), passband, 'UniformOutput', false);
                for i = 1:length(pb_lab)
                    pb_lab_a(i) = {[char(pb_lab(i,1)), '-' char(pb_lab(i,2))]};
                end
                pb_lab_a(1) = {'1-40'};
                plot(R); hold on; plot(model_wts); plot(mw2)
                leg = legend({'R', 'SS err scaled to 1', 'model weights'}); leg.FontSize = 14;
                hline(final_accuracy, 'g', ['weighted prediction of the ensemble: ', num2str(final_accuracy)])
                hline(0)
                tit = xlabel('Passbands of models in ensemble'); tit.FontSize = 14;
                ax = gca;
                ax.XTickLabels = pb_lab_a;
                ax.FontSize = 14;
                grid on

                % plot topographies by model:
                figure
                for st = 1:size(AA,1)
                    subplot(4,4,st)
                    topoplot(squeeze(AA(st,:,1)), EEG.chanlocs,'style','both','electrodes','labelpoint');
                    addr = find(passband(:,3)==st);
                    passband_edge = passband(addr,1:2);
                    tit = title({['Passband: ', num2str(passband_edge), ' Hz'],...
                        ['R^{2} on test set: ', num2str(R(st))]});
                    tit.FontSize = 14;
                end
            end

    %         error('stop')

        else
            % if we don't want to do AdaBoost, just load the first dataset
            % with the full passband
            EEG = pop_loadset(...
                'filepath', '/Volumes/Transcend/10_ads/ensemble_data/',...
                'filename', ['dat_1', '.set']);
            [C, C_z, C_beau, z_train, ad] = get_cov_z(EEG, train_ads, elect_subj, quest);
            [C_z_white, M] = get_white_C_z(C_beau, C_z);
            [W, A] = spoc_l(C_z_white, M, C_beau);
            [r_train, z_tilde_train, resid] = evaluate_model(W, C_z, C, C_beau, z_train);
            [r_test, z_tilde_test, z_test] = test_model(W, EEG, test_ads, elect_subj, quest);
            final_accuracy = corr(z_tilde_test, z_test);
        end


        % create some plots if not adaboost
        if adaboost == 0 & silent==0
            figure;
            subplot(2,2,1)
            topoplot(W(:,1), EEG.chanlocs,'style','both','electrodes','labelpoint');
            tit = title({'w from SPoC_{\lambda}', a{quest}}); tit.FontSize = 14;

            subplot(2,2,3)
            % topoplot(w'*C_beau, EEG.chanlocs,'style','both','electrodes','labelpoint');
            topoplot(A(:,1), EEG.chanlocs,'style','both','electrodes','labelpoint');
            tit = title({'w^{T} C from SPoC_{\lambda}', a{quest}}); tit.FontSize = 14;

            subplot(2,2,2)
            imagesc(C_z_white)
            tit = title('Covariance matrix, Cz white'); tit.FontSize = 14;

            subplot(2,2,4)
            plot(z_test); hold on
            plot(z_tilde_test)
            grid on; hline(0)
            tit = title({['Corr (z, z(tilde)) on test ad #', num2str(test_ads),': ', num2str(r_test)],...
                a{quest},...
                ['Sum of squared errors: ', num2str(round(sumsqr(z_test - z_tilde_test), 2))]});
            tit.FontSize = 14;
            xlab = xlabel('subjects'); xlab.FontSize = 14;
            score = xlabel('subjects'); xlab.FontSize = 14;
            leg = legend({'GT', 'Prediction'}); leg.FontSize = 14;
        end

    end
end
fclose(fileID);
%%
function [r_test, z_tilde_test, z_test] = test_model(W, EEG, test_ads, elect_subj, quest)
    [C, C_z, C_beau, z, ad] = get_cov_z(EEG, test_ads, elect_subj, quest);
    [C_z_white, M] = get_white_C_z(C_beau, C_z);
    [r, z_tilde, resid] = evaluate_model(W, C_z, C, C_beau, z);
    z_test = z;
    r_test = r;
    z_tilde_test = z_tilde;
end


function [r, z_tilde, resid] = evaluate_model(W, C_z, C, C_beau, z)
    w = W(:,1);
    enum = (w' * C_z * w)^2;
    denom = zeros(size(C,1), 1);
    for i = 1:size(C,1)
        denom(i) = (w' * (squeeze(C(i,:,:)) - C_beau) * w)^2;
    end
    denom = mean(denom);
%     r = sqrt(enum/denom); % this may get the sign wrong
    
    z_tilde = zeros(length(z), 1);
    for i = 1:length(z)
        z_tilde(i) = w'*(squeeze(C(i,:,:))-C_beau)*w;
    end
    z_tilde = (z_tilde-mean(z_tilde(:)))./std(z_tilde(:));
%     disp([corr(z, z_tilde), r])
    r = corr(z, z_tilde);
    resid = z - z_tilde;
end

function [C, C_z, C_beau, z, ad] = get_cov_z(EEG, ads, elect_subj, quest)
    % get ad-wise covariances, C(e), and raw scores, z(e)
    C = zeros(length(ads)*length(elect_subj), 32, 32);
    C_z = zeros(length(ads)*length(elect_subj), 32, 32);
    z = zeros(length(ads)*length(elect_subj), 1);
    ad = zeros(length(ads)*length(elect_subj), 1);
    c = 0;
    for i = ads
        for s = elect_subj
            c = c + 1;
            x = find(ismember([EEG.event.code], i) & ismember({EEG.event.subj}, s));
    %         disp([num2str(i), s,  num2str(min(x)), num2str(max(x))])
            xx = EEG.data(:, round(EEG.event(min(x)).latency):round(EEG.event(max(x)).latency));
            C(c,:,:) = cov(xx');
            z(c) = EEG.event(min(x)+1).score(quest);
            ad(c) = i;
        end
    end
    % center the z and scale to unit variance:
    z = (z-mean(z(:)))./std(z(:));
    
    % get C_z and C
    c = 0;
    for i = ads
        for s = elect_subj
            c = c + 1;
            C_z(c,:,:) = squeeze(C(c,:,:)) * z(c);
        end
    end
    C_beau = squeeze(mean(C,1));
    C_z = squeeze(mean(C_z,1));
end

function [C, C_z, C_beau, z, ad] = resample_data(EEG, ads, elect_subj, quest, new_samp_idx)
    % get ad-wise covariances, C(e), and raw scores, z(e)
    C = zeros(length(ads)*length(elect_subj), 32, 32);
    C_z = zeros(length(ads)*length(elect_subj), 32, 32);
    z = zeros(length(ads)*length(elect_subj), 1);
    ad = zeros(length(ads)*length(elect_subj), 1);
    c = 0;
    for i = ads
        for s = elect_subj
            c = c + 1;
            x = find(ismember([EEG.event.code], i) & ismember({EEG.event.subj}, s));
    %         disp([num2str(i), s,  num2str(min(x)), num2str(max(x))])
            xx = EEG.data(:, round(EEG.event(min(x)).latency):round(EEG.event(max(x)).latency));
            C(c,:,:) = cov(xx');
            z(c) = EEG.event(min(x)+1).score(quest);
            ad(c) = i;
        end
    end
    
    % resample C, z and ad
    C = C(new_samp_idx,:,:);
    z = z(new_samp_idx);
    ad = ad(new_samp_idx);
    % center the z and scale to unit variance:
    z = (z-mean(z(:)))./std(z(:));
    
    % get C_z and C
    c = 0;
    for i = ads
        for s = elect_subj
            c = c + 1;
            C_z(c,:,:) = squeeze(C(c,:,:)) * z(c);
        end
    end
    C_beau = squeeze(mean(C,1));
    C_z = squeeze(mean(C_z,1));
end

function [W, A] = spoc_l(C_z_white, M, C_beau)
    % compute SPoC in whitened space. Here the covariance matrix is the
    % identity and thus the generalized eigenvalue problem is reduced to an
    % ordinary eigenvalue problem
    % [W, D] = eig(C_beau, C_z);
    [W, D] = eig(C_z_white);
    [lambda_values, sorted_idx] = sort(diag(D), 'descend');
    W = W(:, sorted_idx);
    W = M'*W; % project back to original (un-whitened) channel space
    A = C_beau * W / (W'* C_beau * W); % compute patterns
    % A = C_beau * W; % compute patterns
end

function [C_z_white, M] = get_white_C_z(C_beau, C_z)
    % get whitening matrix, M, and whiten C_z:
    M = sqrtm(C_beau);
    C_z_white = M * C_z * M';
end

function [] = build_datasets(passband)
    disp('Rebuilding datasets...')
    for i = 1:size(passband,1)
        addr = find(passband(:,3)==i);
        passband_edge = passband(addr,1:2);
        disp(['Passband edge: ', num2str(passband_edge)])
        path = '/Volumes/Transcend/10_ads/ensemble_data/';
        OUTfilename = ['dat_', num2str(i), '.set'];
        EEG = pop_loadset('filepath', '/Volumes/Transcend/10_ads/', 'filename', 'ten_subj_ica.set');
        if i > 1
            EEG = pop_eegfiltnew(EEG, passband_edge(1), passband_edge(2));
        end
        EEG = pop_saveset(EEG, 'filename', OUTfilename, 'filepath', path, 'check', 'off', 'savemode', 'onefile');
    end
end