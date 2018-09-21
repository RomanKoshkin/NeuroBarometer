% pop_selectcomps(EEG, 1:20);

first_event = 1;
last_event = 400;
lat = [EEG.event.latency];


first_latency = lat(first_event);
last_latency = lat(last_event);

figure
plot(EEG.icaact(1,first_latency:last_latency))
hold on
plot(EEG.icaact(2,first_latency:last_latency) + 200)
plot(EEG.icaact(3,first_latency:last_latency) - 150)
plot(EEG.icaact(4,first_latency:last_latency) - 300)
plot(EEG.icaact(5,first_latency:last_latency) - 450)
plot(EEG.icaact(6,first_latency:last_latency) - 600)
plot(EEG.icaact(7,first_latency:last_latency) - 750)
leg = legend ({'Comp.1', 'Comp.2', 'Comp.3','Comp.4', 'Comp.5', 'Comp.6', 'Comp.7'});
leg.FontSize = 14;
vline(lat(first_event:4:last_event))

