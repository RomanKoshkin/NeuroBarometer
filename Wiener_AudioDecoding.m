%Simple Wiener filter for each block of data 
clc;
clear all;
close all;
hdrFileName = 'NBR000002.vhdr';

filePath=['/home/asus/MyProjects/Neurobarometer/'];  %%% path to data files. PLEASE correct!!!
SignalDurationMax = 60*60*60; % sec. - set a big number if wants to read the whole file
ChannelsTotal = 63;
Res=0.048; 
fs=1000; 
DP=SignalDurationMax*fs; 
chans=[1:ChannelsTotal];

srange=[1 DP]; % read the full file            
            
%%% Read data
disp('File reading...')
tic;
[EEG, MARKER, DataPoints] = pop_loadbv_mja(filePath, hdrFileName, srange, chans);
disp('Done.')
TotalReadingTimeInSeconds = toc;
fprintf('Total reading time, sec: %d \n', ceil(TotalReadingTimeInSeconds)); 
TotalSecondInFile = ceil(length(EEG(1).data)/fs) - 1;
fprintf('Total seconds in file: %d \n',TotalSecondInFile); 
% make EEG datamatrix
for i=1:62
    X0(i,:) = EEG(i).data;
end
% make Audio chanel 
Z = -EEG(63).data;
Z = Z-min(Z);
[blp,alp] = butter(3,120/(fs/2),'low');
Zrect = filtfilt(blp,alp,abs(Z));
Zrect = abs(hilbert(Z));

%clean the data
[b,a] = butter(3,[0.5]/(fs/2),'high');
X = filtfilt(b,a,X0')';
[W,S] = runica(X(:,1:fix(size(X,2)/4)));
Y = W*S*X;
for i=1:size(Y,1)
    MI(i) = fastmutinf1([Y(i,:);X(35,:)]);
end;
figure
stem(MI);
ind_art = [1,20];
V = inv(W*S);
V(:,ind_art) = [];
Y(ind_art,:) = [];
Xc = V*Y;

%find events and create segments
Ev = zeros(1,size(Z,2));
b_last = 1;
for m = 1:length(MARKER)
    if(~isempty(MARKER(m).desc))
        t = str2num(MARKER(m).desc(4));
        Ev(b_last:MARKER(m).latency) = t;
        D{m} = Xc(:,b_last:MARKER(m).latency);
        A{m} = Zrect(1,b_last:MARKER(m).latency);
        E(m) = t;
        b_last = MARKER(m).latency+1;
    end;
end;

for m=1:length(D)
    Rxx{m} = 1/length(A{m})*D{m}*D{m}';
    Rxz{m} = 1/length(A{m})*D{m}*A{m}';
    scale= trace(Rxx{m})/size(Rxx{m},1);
    p{m} = inv(Rxx{m}+0.01*scale*eye(size(Rxx{m})))*Rxz{m};
    d{m} = p{m}'*D{m}-A{m};
    normd(m) = norm(d{m})/norm(A{m});
end;
