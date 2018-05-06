%% extract freqs of interest:
% B0403T

DOMAIN = 0;

class1 = find([EEG.event.type]==769)';
class1(:,2) = repmat(0,[length(class1) 1]);
class2 = find([EEG.event.type]==770)';
class2(:,2) = repmat(1,[length(class2) 1]);

addr = cat(1,class1, class2);
addr = sortrows(addr,1);

addr_latency = ([EEG.event(addr(:,1)).latency] + 0.5*EEG.srate)';

if DOMAIN == 0
    
    X = zeros(length(addr_latency), 3, 2*EEG.srate);
    for i = 1:length(addr_latency)
        X(i,:,:) = EEG.data(1:3, addr_latency(i):addr_latency(i)+2*EEG.srate-1);
        Y(i) = addr(i,2);
        disp(i)
    end
    Z = Y;
    Z = Z';
    Y = Y';
    disp(size(X))
    save('/Users/RomanKoshkin/Downloads/BCI_0703T_TD.mat', 'X', 'Y', 'Z')    
end

if DOMAIN == 1
    
    window_len = 64; % 100
    noverlap = 50;
    nfft = 512;
    
    X = zeros(length(addr_latency), 31, 32, 3);
    for i = 1:length(addr_latency)
          
        for j = 1:3
            [S,F,T] = spectrogram(EEG.data(j,addr_latency(i):addr_latency(i)+2*EEG.srate-1),...
                window_len,noverlap,nfft,EEG.srate);
%             X(i,:,:,j) = abs([S(13:28,:); imresize(S(36:63,:), [15, 32])]).^2;
%             X(i,:,:,j) = abs(imresize(S, [31, 32])).^2;
            X(i,:,:,j) = abs(imresize(S(1:17,:), [31, 32])).^2; 
        end
        Y(i) = addr(i,2);
        disp(i)
    end
    Z = Y;
    Z = Z';
    Y = Y';
    disp(size(X))
    save('/Users/RomanKoshkin/Downloads/BCI_FD.mat', 'X', 'Y', 'Z')   
end

