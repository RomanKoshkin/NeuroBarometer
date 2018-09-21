load('lookup_tab.mat')

for i = 1:11
    i
    folder = lookup_tab{i,1};
    path = ['/Volumes/Transcend/NeuroBarometer/beeps_1/', folder];
    filename = [folder, '.set'];
    EEG = pop_loadset('filepath', path, 'filename', filename);
    eeglab redraw
    EEG = pop_select(EEG, 'channel', [1:63]);
    EEG = eeg_checkset(EEG);
    eeglab redraw
    EEG = pop_runica(EEG, 'icatype', 'binica', 'extended', 1);
    eeglab redraw
    OUTfilename = [folder, '_ICA.set'];
    EEG = pop_saveset(EEG, 'filename', OUTfilename, 'filepath', path, 'check', 'on', 'savemode', 'onefile');
    play_tone(3000, 0.9, 0.2);
    pop_delset(ALLEEG, 1);
    eeglab redraw
    play_tone(2000, 0.9, 0.2);
end
