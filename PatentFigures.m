%% Figure YY

f = 440;
fs = 10000;
T = 0.050;
t = 0:1/fs:T;
x = sin(2*pi*f*t);


x(1:51) = x(1:51).*((1:51)/51);
x(451:501) = x(451:501).*(flip(1:51)/51);

plot(t,x)
ax = gca;
ax.FontSize = 14;
%% Figure QQ
cd /Users/RomanKoshkin/Documents/MATLAB/NeuroBarometer
eeglab
EEG = pop_loadset('filepath', '/Volumes/Transcend/10_ads/','filename', 'fourteen_subj_ica.set');
[ERP1, ~] = plot_eq(EEG,0);
[ERP2, ~] = plot_eq(EEG,3);
% [ERP3, ~] = plot_eq(EEG,14);
% [ERP4, ~] = plot_eq(EEG,15);
t = -100:5:295;

plot(t, squeeze(mean(ERP1(:,15,:))), 'Color', 'k', 'LineWidth', 2)
hold on
plot(t, squeeze(mean(ERP2(:,15,:))), 'LineStyle', '--', 'Color', 'k', 'LineWidth', 2)
% plot(t, squeeze(mean(ERP3(:,15,:))))
% plot(t, squeeze(mean(ERP4(:,15,:))))
grid on
vline(0); hline(0)
x = [0 50 50 0];
y = [-1.5 -1.5 1 1];
h = fill(x,y, [0.05 0.05 0.05]); h.FaceAlpha=0.3;
xlabel('ms')
ylabel('\muV')
legend({'????????? 1', '????????? 2'})
ax = gca;
ax.FontSize = 14;
