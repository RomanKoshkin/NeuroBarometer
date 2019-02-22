% plot_eq_data.m 
% returns a 3D matrix of ERPs for specific ads
function [ERP, se] = plot_eq_data(EEG, ad, data)
    a = find(ismember([EEG.event.type], ad) & ismember({EEG.event.dataset}, data));
%     a = find(ismember([EEG.event.type], ad));
        
    chan = 1:length(EEG.chanlocs);
    lats = round([EEG.event(a).latency]);

    ERP = zeros(length(a),length(chan), 80);

        for i = 1:length(a)
            ERP(i,:,:) = EEG.data(chan, lats(i)-20:lats(i)+59);
            baseline = mean(ERP(i,:,1:20),3)';
            ERP(i,:,:) = squeeze(ERP(i,:,:)) - baseline;
        end
        se = squeeze(std(ERP,0, 1))/sqrt(size(ERP,1));
end