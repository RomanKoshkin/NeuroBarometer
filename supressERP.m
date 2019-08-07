function [EEG] = supressERP(EEG, window)
    a = find(~ismember({EEG.event.type},'boundary'));
    lats = round([EEG.event(a).latency]);
    for i = 1:length(lats)
        for ch = 1:32
            EEG.data(ch, lats(i)-20:lats(i)+59) = EEG.data(ch, lats(i)-20:lats(i)+59).*window;
        end
    end
end