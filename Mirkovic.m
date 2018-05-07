%% Mirkovic
clear
clc
% load('/Users/RomanKoshkin/Downloads/Mirkovic_data/EEG_04_60.mat')
load('/Users/RomanKoshkin/Downloads/Mirkovic_data/EEG_02_60.mat')
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
en = 100;
LAMBDA = 0.03;
WLEFT = zeros(ch_num,21,48);
WRIGHT = zeros(ch_num,21,48);
LCON_L = zeros(ch_num,48);
LCON_R = zeros(ch_num,48);

parfor i = 1:length(EEG)
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

W_ATT = mean(W_ATT,3);
W_UNATT = mean(W_UNATT,3);
LCON_att = mean(LCON_att,2);
LCON_unatt = mean(LCON_unatt,2);

S = struct ('a_r_att', [], 'a_r_unatt', [], 'success', []);

for j = 1:length(EEG)
    disp(j)
    stimAtt = AudioEnv{j}(att_ch,:)';
    stimUnatt = AudioEnv{j}(unatt_ch,:)';
    response = EEG{j}(:,:)';
    
    [~, S(j).a_r_att, ~, ~] = mTRFpredict(stimAtt, response, W_ATT, Fs, 1, or, en, LCON_att);
    [~, S(j).a_r_unatt, ~, ~] = mTRFpredict(stimUnatt, response, W_UNATT, Fs, 1, or, en, LCON_unatt);
    S(j).success = (S(j).a_r_att > S(j).a_r_unatt);
end

acc = mean([S.success]);
disp(['Accuracy: ' num2str(acc)]);

