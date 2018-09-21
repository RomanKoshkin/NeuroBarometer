counter = 0;
for i = 1:length({EEG.event.type})
    if strcmp(EEG.event(i).type, 'Nachalo audio')==1
        counter = counter + 1;
    end
    if strcmp(EEG.event(i).type, 'Bip')==1
        EEG.event(i).type = num2str(counter);
    end
end
    