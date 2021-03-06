X = [];
Y = [];
for j = 1:length(x)
    start_time = x(j,1);
    end_time = start_time + 2*srate-1;
    for i = 1:8
        X = cat(3, X, data_cur(:,start_time:end_time));
        Y = cat(1, Y,states_cur(start_time));
        Z = Y;
        start_time =  end_time + 1;
        end_time = start_time + 2*srate-1;
    end
end

get_rid_of = find(Z==6);
X(:,:,get_rid_of) = [];
Y(get_rid_of) = [];
Z(get_rid_of) = [];

X = permute(X,[3,1,2]);

window_len = 64; % 100
noverlap = 50;
nfft = 512;
EL_CHANS = [4 5 6 15 16 17 26 27];

SS = zeros(size(X,1),32, 32,length(EL_CHANS));
for i = 1:size(X,1)
    for j = 1:length(EL_CHANS)
        [S,F,T] = spectrogram(squeeze(X(i,EL_CHANS(j),:)), window_len,noverlap,nfft,srate);
        SS(i,:,:,j) = imresize((abs(S(5:37,:))).^2, [32 32]);
        disp(i)
    end
end
X = SS;


k = 20;
figure
subplot(1,2,1)
imagesc(squeeze(SS(k,:,:,4)))
subplot(1,2,2)
imagesc(imresize(squeeze(SS(k,:,:,4)), [32,32]))