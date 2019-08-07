% returns a 3D matrix of ERPs for specifiec ads selected based on their
% order in the dataset
function [ERP, se] = plot_e_ord(EEG, ord, subj)
    
    a = find(ismember([EEG.event.ord], ord) & ismember({EEG.event.subj}, subj));
%     a = find(ismember([EEG.event.ord], ord));
    
    chan = 1:length(EEG.chanlocs);
    lats = round([EEG.event(a).latency]);

    ERP = zeros(length(a),length(chan), 80);

        for i = 1:length(a)
            if lats(i)-20 < 1
                continue
            end
            ERP(i,:,:) = EEG.data(chan, lats(i)-20:lats(i)+59);
            baseline = mean(ERP(i,:,1:20),3)';
            ERP(i,:,:) = squeeze(ERP(i,:,:)) - baseline;
        end
        se = squeeze(std(ERP,0, 1))/sqrt(size(ERP,1));
end