EEG1 = pop_select(EEG, 'time', [35 105]);
[EEG1, ~, ~] = pop_eegfiltnew(EEG1, 1, 48);
% EEG1 = pop_runica(EEG1, 'icatype', 'binica', 'extended', 1, 'maxNumIterations', 1000);
EEG1 = pop_runica(EEG1, 'icatype', 'jader');
pop_eegplot( EEG1, 1, 0, 1);
EEG2 = EEG1;
EEG2.data = EEG2.icaact;
pop_eegplot( EEG2, 1, 0, 1);