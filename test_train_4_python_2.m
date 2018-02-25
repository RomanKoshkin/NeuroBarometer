clear
% load('KOS_DAS_80Hz.mat')
load('BIG.mat')
load('output.mat') % stores a lot of things, including the two decoders.
clearvars -except EEG S

% data split:
counter = 0;
for i = 1:length({S.type})
    start = round(S(i).latency);
    fin = start + 10 * EEG.srate-1;
    while fin < S(i).latency + 30*EEG.srate
        counter = counter + 1;
        X(counter,:,:) = EEG.data(1:60,start:fin);
        if strcmp(S(i).type, 'right') == 1
            Y(counter,:) = EEG.data(62,start:fin);
            disp([num2str(counter) '_' S(i).type ' right, trial = ', num2str(i)])
        else
            Y(counter,:) = EEG.data(61,start:fin);
            disp([num2str(counter) '_' S(i).type ' left, trial = ', num2str(i)])
        end
        start = fin + 1;
        fin = start + 10 * EEG.srate-1;    
    end
end
save('EEG_big.mat', 'X', 'Y')