%% first run bip.c (block 1, project the scores if necessary, 
% load projected scores to EEG.event struct (block2)
% determine what's low, mid and high (this code down)

chan = 17;

responses = [EEG.event.response1]';

k = 1
quant = [0.33 0.66];
var_of_interest = k;

% lo_co = quantile(responses(:, var_of_interest), quant(1));
% hi_co = quantile(responses(:, var_of_interest), quant(2));
lo_co = quantile(responses(:, var_of_interest), 0.5);
hi_co = quantile(responses(:, var_of_interest), 0.5);



LO_idx = find(responses(:,var_of_interest) <= lo_co);
HI_idx = find(responses(:,var_of_interest) >= hi_co);
% MID_idx = find(not(responses(:,var_of_interest) <= lo_co) &...
%     not(responses(:,var_of_interest) >= hi_co));

[EEG.event.resp] = deal([]);
[EEG.event(LO_idx).resp] = deal('low');
% [EEG.event(MID_idx).resp] = deal('mid');
[EEG.event(HI_idx).resp] = deal('high');

%%
lat_ids = find(~ismember([EEG.event.third], 0));
TR = [find(t==130):find(t==170)];
chan = 17;

global EEG
[X, N1, Z] = ERPs_2(chan, TR, lat_ids);
SE = std(Z,1)/sqrt(size(Z,1));

data = EEG.event;
data = rmfield(data,{'response1', 'sc', 'urevent','code', 'bvmknum', 'bvtime', 'channel', 'duration'});
data([data.third]==0) = [];
writetable(struct2table(data), 'df.csv')

csvwrite('N1.csv', [X(chan,:)' SE'])


figure;
subplot(1,2,1)
histogram(N1)
subplot(1,2,2)
plot(t, X(chan,:))