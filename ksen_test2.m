clear
load('ksenia2_long.mat')

hi_stopband = 0.5;
hi_passband = 1;
lo_passband = 60;
lo_stopband = 61;
order = 500;

X_hat = notch50(data_cur,srate);
X_hat = bandpassFIR(X_hat, srate, lo_passband, lo_stopband, order, hi_stopband, hi_passband);
% X_hat = bandstopFIR(X_hat, 8, 8.5, 12, 12.5, srate);

% S = fft(data_cur(11,:));
% L = length(data_cur);
% P2 = abs(S/L);
% P1 = P2(1:L/2+1);
% P1(2:end-1) = 2*P1(2:end-1);
% f = srate*(0:(L/2))/L;
% plot(f,P1) 


plot(data_cur(12,1:500));hold on;plot(X_hat(12,1:500))

X = [];
Y = [];
for j = 1:length(x)
    start_time = x(j,1);
    end_time = start_time + 500-1;
    for i = 1:67
        X = cat(3, X, X_hat(:,start_time:end_time));
        Y = cat(1, Y,states_cur(start_time));
        Z = Y;
        start_time =  end_time + 1;
        end_time = start_time + 500-1;
        if end_time > length(X_hat)
            break
        end
    end
end

get_rid_of = find(Z==6);
X(:,:,get_rid_of) = [];
Y(get_rid_of) = [];
Z(get_rid_of) = [];

X = permute(X,[1,3,2]);

save('ksenia2_long_chunked.mat', 'X', 'Y', 'Z')
error('asdfa')
%% FREQUENCY DOMAIN


window_len = 64; % 100
noverlap = 50;
nfft = 512;
EL_CHANS = 1:24;

SS = zeros(size(X,1),32, 32,length(EL_CHANS));
for i = 1:size(X,1)
    for j = 1:length(EL_CHANS)
        [S,F,T] = spectrogram(squeeze(X(i,:, j)), window_len,noverlap,nfft,srate);
        SS(i,:,:,j) = imresize((abs(S(5:37,:))).^2, [32 32]);
        disp(i)
    end
end
X = SS;
save('ksenia2_long_chunked_FD.mat', 'X', 'Y', 'Z')

k = 20;
figure
subplot(1,2,1)
imagesc(squeeze(SS(k,:,:,4)))
subplot(1,2,2)
imagesc(imresize(squeeze(SS(k,:,:,4)), [32,32]))