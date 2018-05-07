%% Mirkovic
clear
clc
load('/Users/RomanKoshkin/Downloads/Mirkovic_data/EEG_04_60.mat')
% load('/Users/RomanKoshkin/Downloads/Mirkovic_data/EEG_02_60.mat')
EEG = EEGBlock;

load('/Users/RomanKoshkin/Downloads/Mirkovic_data/AudioEnv60.mat')
sz = size(EEG{1});
ch_num = sz(1);
clear EEGBlock sz
%%
att_ch = 2;
unatt_ch = 1;

Fs = 64;
or = 0;
en = 50;
LAMBDA = 0.03;
WLEFT = zeros(ch_num,21,48);
WRIGHT = zeros(ch_num,21,48);
LCON_L = zeros(ch_num,48);
LCON_R = zeros(ch_num,48);

parfor i = 1:48
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

trials = 1:48;

for k = 1:48;
    disp(['Predicting Trial ' num2str(k)])
    temp_trials = trials;
    temp_trials(k) = [];

    W_ATT_tmp = mean(W_ATT(:,:,temp_trials),3);
    W_UNATT_tmp = mean(W_UNATT(:,:,temp_trials),3);
    LCON_att_tmp = mean(LCON_att(:,temp_trials),2);
    LCON_unatt_tmp = mean(LCON_unatt(:,temp_trials),2);
    
    stimAtt = AudioEnv{k}(att_ch,:)';
    stimUnatt = AudioEnv{k}(unatt_ch,:)';
    response = EEG{k}(:,:)';
    
    [~, S(k).a_r_att, ~, ~] = mTRFpredict(stimAtt, response, W_ATT_tmp, Fs, 1, or, en, LCON_att_tmp);
    [~, S(k).a_r_unatt, ~, ~] = mTRFpredict(stimUnatt, response, W_UNATT_tmp, Fs, 1, or, en, LCON_unatt_tmp);
    S(k).success = (S(k).a_r_att > S(k).a_r_unatt);

end

disp(['Cross-Validation Accuracy: ' num2str(mean([S.success]))]) 
