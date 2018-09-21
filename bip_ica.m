close all
load('a.mat')
load('scores.mat')
load('lookup_tab.mat')

% EEG = pop_loadset('filepath', '/Volumes/Transcend/NeuroBarometer/beeps_1/', 'filename', '1-6.set');
EEG = pop_loadset('filepath', '/Volumes/Transcend/NeuroBarometer/beeps_1/', 'filename', 'all.mat');

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
load('scores.mat')
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

EEG = pop_select(EEG, 'channel', [1:63]);
play_tone(440, 0.9, 0.2);
%%
k = 6

ds_ids = unique({EEG.event.dataset})'; ds_ids(1) = [];

ids = find(ismember({EEG.event.dataset}, ds_ids(k)));
point_rng = round([EEG.event(min(ids)).latency EEG.event(max(ids)).latency]);


OUTEEG = pop_select(EEG, 'point', point_rng);


OUTEEG_ICA = pop_runica(OUTEEG, 'icatype', 'binica', 'extended', 1);

pop_selectcomps(OUTEEG_ICA, 1:10);
play_tone(3000, 2, 2);


size(EEG.data(:,[point_rng(1):point_rng(2)]))
size(OUTEEG_ICA.data)

error('INSPECT COMPONENTS');
%%
OUTEEG_ICA_C = pop_subcomp(OUTEEG_ICA, [1 2]);
pop_eegplot(OUTEEG_ICA, 1, 0, 1);
pop_eegplot(OUTEEG_ICA_C, 1, 0, 1);

EEG.data(:,[point_rng(1):point_rng(2)]) = OUTEEG_ICA_C.data;
save('/Volumes/Transcend/NeuroBarometer/beeps_1/EEG_tmp_ICA.mat', 'EEG', '-v7.3')
play_tone(300, 2, 2);