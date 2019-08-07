% plot_eq_subj.m 
% returns a 3D matrix of ERPs for specific ads
function [ERP, se, z] = plot_eq_subj(EEG, ad, subj)
    % ad = [3    14    15    19    23    24    25    30    39    47];
    chan = [1:32];

    a = find(ismember([EEG.event.code], ad) & ismember({EEG.event.subj}, subj));
    lats = round([EEG.event(a).latency]);

    ERP = zeros(length(a),length(chan), 80);
    z = zeros(length(a), 10);

        for i = 1:length(a)
            if lats(i)-20 < 1
                continue
            end
            ERP(i,:,:) = EEG.data(chan, lats(i)-20:lats(i)+59);
            baseline = mean(ERP(i,:,1:20),3)';
            ERP(i,:,:) = squeeze(ERP(i,:,:)) - baseline;
            if isempty(EEG.event(a(i)).score) == 0
                z(i,:) = [EEG.event(a(i)).score];
            else
                z(i,:) = repmat(NaN,1,10);
            end
        end
        se = squeeze(std(ERP,0, 1))/sqrt(size(ERP,1));
        
end