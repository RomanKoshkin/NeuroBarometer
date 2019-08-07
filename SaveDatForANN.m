quest = 1:10;
ads =       [3    14    15    19    23    24    25    30    39    47];
chan = 15;

for quest = quest
    for i = 1:10    
        test_ads = ads(comb(i,:));
        train_ads = ads(~ismember(ads, test_ads));
        [X_train, f, z_train, ad_train] = get_set(EEG, train_ads, quest, chan);
        [X_test, f, z_test, ad_test] = get_set(EEG, test_ads, quest, chan);
        file = ['/Users/RomanKoshkin/Downloads/FFTdat_ad',...
            num2str(i), '_q', num2str(quest), '.mat'];
        save(file, 'X_train', 'z_train', 'X_test', 'z_test')
    end
end

function [PXX, f, z, ad] = get_set(EEG, ads, quest, chan)
    elect_subj = {'Deryabin', 'Kabanov', 'Kabanova', 'Sukhanova', 'Vishnyakova', 'Karpinskaya', 'Orlichenya'};
    number_of_frequencies = 50;
    PXX = zeros(length(ads)*length(elect_subj), 26);
    z = 0;
    c = 0;
    ad = [];
    for i = ads
        for s = elect_subj
            c = c + 1;
            x = find(ismember([EEG.event.code], i) & ismember({EEG.event.subj}, s));
            xx = EEG.data(:, round(EEG.event(min(x)).latency):round(EEG.event(max(x)).latency));
            [pxx,f] = periodogram(xx(chan,:),[], number_of_frequencies, EEG.srate, 'power', 'onesided');
            PXX(c,:) = pxx';          
            z(c) = EEG.event(min(x)+1).score(quest);
            ad(c,1) = i;
        end
    end
    % center the z and scale to unit variance:
    z = ((z-mean(z(:)))./std(z(:)))';
end