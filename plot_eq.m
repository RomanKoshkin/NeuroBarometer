% plot_eq.m 
% returns a 3D matrix of ERPs for specific ads
function [ERP, se] = plot_e(EEG, ad)
%     a = find(ismember([EEG.event.type], ad) & ismember({EEG.event.dataset}, 'Original file: NeoRec_2018-07-04_22-18-39.eeg')); % for 64 chan (old 50-ad dat)
    
    a = find(ismember([EEG.event.code], ad));
    
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