%% based on the lookup.mat adds information to the currently loaded dataset about ad numbers

%% -------------- 1 ---------------------
a = [EEG.event.latency];
b = diff(a);
b = [0 b];
figure

count = 0;
EEG.event(1).code = count;
for i = 2:length(b)
    if b(i)>b(i-1) * 10
        count = count + 1;
    end
        EEG.event(i).code = count;
end

plot(b); hold on
plot([EEG.event.code]*500)

%% -------------- 2 ---------------------
load('lookup.mat')
lookup_tab = lookup.(EEG.setname);

f = ismember([EEG.event.code], 0);
[EEG.event(f).code] = deal(0);
f = ismember([EEG.event.code], 1);
[EEG.event(f).code] = deal(0);

changed = zeros(1,length([EEG.event.code]), 'logical');
for i = 1:10
    rep_from = lookup_tab(i,1);
    rep_to = lookup_tab(i,2);
%     [num2str(rep_from), '  ', num2str(rep_to)]
    to_change = ismember([EEG.event.code], rep_from);
    to_change = and(to_change, not(changed));
    [EEG.event(to_change).code] = deal(rep_to);
    changed = or(changed, to_change);
end
