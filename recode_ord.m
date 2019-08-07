c = 0;
for i = 2:length(EEG.event)
    if isempty(EEG.event(i).code)==1
        continue
    end
    
    if EEG.event(i).code == EEG.event(i-1).code
        EEG.event(i).ord = c;
    else
        c = c + 1;
        if c == 11
            c = 0;
        end
        EEG.event(i).ord = c;
    end
end

emp = find(cellfun(@isempty, {EEG.event.ord}));
[EEG.event(emp).ord] = deal(-1);