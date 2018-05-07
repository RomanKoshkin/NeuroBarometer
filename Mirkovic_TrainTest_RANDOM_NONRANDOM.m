%% Mirkovic

%% datasets:
clear
clc
load('/Users/RomanKoshkin/Downloads/Mirkovic_data/EEG_04_60.mat')
% load('/Users/RomanKoshkin/Downloads/Mirkovic_data/EEG_02_60.mat')
EEG = EEGBlock;

load('/Users/RomanKoshkin/Downloads/Mirkovic_data/AudioEnv60.mat')

sz = size(EEG{1});
ch_num = sz(1);
clear EEGBlock sz


%% parameters:
att_ch = 2;
unatt_ch = 1;
rand_sample = 0;
proportions = 0.2:0.1:0.9;

Fs = 64;
or = 150;
en = 550;
LAMBDA = 0.43;

for split = 1:length(proportions)
    disp(['Split: ' num2str(split)])
    
    if rand_sample==1
        training_trials = randsample(1:48, floor(quantile(1:48,proportions(split))));
        testing_trials = 1:48;
        testing_trials(training_trials) = [];
    else
        training_trials = 1:floor(quantile(1:48,proportions(split)));
        testing_trials = [(training_trials(end)+1):48];
    end
    
    disp ('TRAINING TRIALS:')
    disp(training_trials)
    disp ('TESTING TRIALS:')    
    disp (testing_trials)        
    

    WLEFT = zeros(ch_num,21,length(training_trials));
    WRIGHT = zeros(ch_num,21,length(training_trials));
    LCON_L = zeros(ch_num,length(training_trials));
    LCON_R = zeros(ch_num,length(training_trials));

    for i = training_trials
        disp(i)
        stimAtt = AudioEnv{i}(att_ch,:)';
        stimUnatt = AudioEnv{i}(unatt_ch,:)';
        response = EEG{i}(:,:)';
        [w_att,t, Lcon_L] = mTRFtrain(stimAtt, response, Fs, 1, or, en, LAMBDA);
        [w_unatt,t, Lcon_R] = mTRFtrain(stimUnatt, response, Fs, 1, or, en, LAMBDA);
        W_ATT(:,:,i) = w_att;
        W_UNATT(:,:,i) = w_unatt;
        LCON_att(:,i) = Lcon_L;
        LCON_unatt(:,i) = Lcon_R;
    end


    W_ATT_tmp = mean(W_ATT,3);
    W_UNATT_tmp = mean(W_UNATT,3);
    LCON_att_tmp = mean(LCON_att,2);
    LCON_unatt_tmp = mean(LCON_unatt,2);
    
    S = struct ('a_r_att', [], 'a_r_unatt', [], 'success', []);

    for k = testing_trials
        disp(['Predicting Trial ' num2str(k)])
        stimAtt = AudioEnv{k}(att_ch,:)';
        stimUnatt = AudioEnv{k}(unatt_ch,:)';
        response = EEG{k}(:,:)';

        [~, S(k).a_r_att, ~, ~] = mTRFpredict(stimAtt, response, W_ATT_tmp, Fs, 1, or, en, LCON_att_tmp);
        [~, S(k).a_r_unatt, ~, ~] = mTRFpredict(stimUnatt, response, W_UNATT_tmp, Fs, 1, or, en, LCON_unatt_tmp);
        S(k).success = (S(k).a_r_att > S(k).a_r_unatt);
    end
    
    acc(split) = mean([S.success]);
    disp(['Accuracy: ' num2str(mean([S.success]))])
end
plot(proportions, acc)