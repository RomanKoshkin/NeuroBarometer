% cd /Users/RomanKoshkin/Documents/MATLAB/NeuroBarometer
% eeglab redraw
% EEG = pop_loadset('filepath', '/Volumes/Transcend/10_ads/','filename', 'fourteen_subj_ica.set');
%%
subjects = {'Vovk', 'Indyukova', 'Buyanova', 'Deryabin', 'Kabanov', 'Kabanova',...
        'Sukhanova', 'Vishnyakova', 'Karpinskaya', 'Orlichenya','Pyzgareva'};

ads = [3    14    15    19    23    24    25    30    39    47];

for quest = 1:10;

    score = zeros(length(ads), length(subj));
    for ad = 1:length(ads)
        for subject = 1:length(subjects)
            idx = find(...
                ismember({EEG.event.subj}, subjects(subject)) &...
                ismember([EEG.event.code], ads(ad)));
            tmp = mean(reshape([EEG.event(idx).score], 10,[]),2);
            score(ad,subject) = tmp(quest);
        end
    end

    score(6,11) = nanmean(score(:,11));

    M = mean(score,2);
    SE = std(score')/sqrt(size(score,2));
    subplot(3,4,quest)
    errorbar(1:10, M, SE)
    title(['Question: ', num2str(quest)])
    ylim([0 11]); xlim([0 11]);
    disp(quest)
end