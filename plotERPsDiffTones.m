% % Roman
% figure
% subplot(2,3,1)
% EEG = pop_loadset(['/Users/RomanKoshkin/Documents/MATLAB/NeuroBarometer/Roma_15jan/Ro1.set']);
% plot_e(EEG)
% 
% subplot(2,3,2)
% EEG = pop_loadset(['/Users/RomanKoshkin/Documents/MATLAB/NeuroBarometer/Roma_15jan/Ro2.set']);
% plot_e(EEG)
% 
% subplot(2,3,3)
% EEG = pop_loadset(['/Users/RomanKoshkin/Documents/MATLAB/NeuroBarometer/Roma_15jan/Ro3.set']);
% plot_e(EEG)
% 
% subplot(2,3,4)
% EEG = pop_loadset(['/Users/RomanKoshkin/Documents/MATLAB/NeuroBarometer/Roma_15jan/Ro4.set']);
% plot_e(EEG)
% 
% subplot(2,3,5)
% EEG = pop_loadset(['/Users/RomanKoshkin/Documents/MATLAB/NeuroBarometer/Roma_15jan/Ro5.set']);
% plot_e(EEG)
% 
% eeglab redraw
% error('asdasdf')
%% compare ERPs and SEs of one channel (say, chan 1) with an average of four fronto-parietal
%  and a virtual channel
ch = 15;

t = -100:5:295;

ERPx = plot_e(EEG, ch, 'Dataset 1');

% TR = [46:63]; Pt = 140; % N1
TR = [26:43]; pt = 80; % P1

selected_ch = ERPx(:,[15,46,49,14,48,18,43,17,51],:);
mean_selected_ch = squeeze(mean(selected_ch,2));

org_ch = squeeze(ERPx(:,ch,:));
se_mean_selected_ch = std(mean_selected_ch,0, 1)/sqrt(size(mean_selected_ch,1));
se_org_ch = std(org_ch,0, 1)/sqrt(size(org_ch,1));

[U,S,V] = svd(squeeze(mean(ERPx(:,:,TR),1)));
comp1 = U(:,1);
comp1 = comp1/(0.5*sum(abs(comp1))); % we norm the eigenvector abs(neg(comp))=abs(pos(comp))
virch = zeros(size(ERPx,1), 80);
for i = 1:size(ERPx,1)
    virch(i,:) = comp1' * squeeze(ERPx(i,:,:));
end
se_virch = std(virch, 0, 1)/sqrt(size(virch,1));

figure
subplot(2,4,[1,2])
plot(t, mean(mean_selected_ch,1))
hold on
plot(t, mean(org_ch,1))
plot(t, mean(virch))
tit = title('ERPs'); tit.FontSize = 14;
ax1 = gca;
ax1.FontSize = 14;
ax1.YLim = [-1 1.5];
ax1.XLim = [-100 300];
leg = legend({'Average of 4 channels', 'Channel 15 (Fz)', 'Vir. chan'}); leg.FontSize = 14;
vline(0); hline(0); grid on

subplot(2,4,[3,4])
plot(t, se_mean_selected_ch, t, se_org_ch, t, se_virch)
hold on
leg = legend({'Average of selected channels', 'Channel 15 (Fz)', 'Virtual Chan'});
tit = title ('Standard error vs. latency post stim onset');
tit.FontSize = 14; leg.FontSize = 14;
ax2 = gca;
ax2.FontSize = 14;
ax2.YLim = [0.0 0.35];
ax2.XLim = [-100 300];
vline(0); hline(0); grid on

subplot(2,4,[7,8])
plot(t, abs(mean(mean_selected_ch,1)./se_mean_selected_ch))
hold on
plot(t,abs(mean(org_ch,1)./se_org_ch))
plot(t,abs(mean(virch,1)./se_virch))
tit = title('ABS Amplitude/SE'); tit.FontSize = 14;
leg = legend({'Average of 4 channels', 'Channel 15 (Fz)', 'Virtual Chan'}); leg.FontSize = 14;
ax3 = gca;
ax3.FontSize = 14;
ax3.XLim = [-100 300];
vline(0); hline(0); grid on

subplot(2,4,[5])
topoplot(U(:,1), EEG.chanlocs,'style','both','electrodes','labelpoint');
tit = title('1st eigenvector weights'); tit.FontSize = 14;

%% BEAMFORMER
ERP = squeeze(mean(ERPx,1));
g = ERP(:,find(t==Pt));
C = ERP*ERP';
% w = g * inv(C).g';
w = (g \ C)'/((g\C)*g); % same but better
w = -w;
z = w'*ERP;
plot(ax1, t, z)
subplot(2,4,[1,2])
leg = legend({'Average of 4 channels', 'Channel 15 (Fz)', 'Vir. chan', 'Beamformer'}); leg.FontSize = 14;
subplot(2,4,6)
topoplot(w, EEG.chanlocs,'style','both','electrodes','labelpoint');
tit = title('BEAMFORMER weights'); tit.FontSize = 14;
vline(0); hline(0); grid on; hold off

Z = zeros(size(ERPx,1), size(ERPx,3));
for i = 1:size(ERPx,1)
    Z(i,:) = w' * squeeze(ERPx(i,:,:));
end
se_bf = std(Z,1)/sqrt(size(Z,1));
plot(ax2, t, se_bf)
subplot(2,4,[3,4])
leg = legend({'Average of 9 channels', 'Channel 15 (Fz)', 'Vir. chan', 'Beamformer'}); leg.FontSize = 14;


plot(ax3, t, abs(z)./se_bf)
subplot(2,4,[7,8])
leg = legend({'Average of 9 channels', 'Channel 15 (Fz)', 'Vir. chan', 'Beamformer'}); leg.FontSize = 14;
%%
% Ivan

ch = 15;

figure
subplot(2,3,1)
EEG = pop_loadset(['/Users/RomanKoshkin/Documents/MATLAB/NeuroBarometer/Ivan_15jan/Iv1.set']);
ERPx = plot_e(EEG, ch, 'Dataset 1');


subplot(2,3,2)
EEG = pop_loadset(['/Users/RomanKoshkin/Documents/MATLAB/NeuroBarometer/Ivan_15jan/Iv2.set']);
ERPx = plot_e(EEG, ch, 'Dataset 2');

subplot(2,3,3)
EEG = pop_loadset(['/Users/RomanKoshkin/Documents/MATLAB/NeuroBarometer/Ivan_15jan/Iv3.set']);
ERPx = plot_e(EEG, ch, 'Dataset 3');

subplot(2,3,4)
[U,S,V] = svd(squeeze(mean(ERPx,1)));
topoplot(U(:,1), EEG.chanlocs,'style','both','electrodes','labelpoint');

subplot(2,3,5)
t = -100:5:295;
comp1 = U(:,1);
comp1 = comp1/(0.5*sum(abs(comp1))); % we norm the eigenvector abs(neg(comp))=abs(pos(comp))

% comp1 = comp1/norm(comp1); % we unitscale the eigenvector

% comp1 = mapminmax(comp1',0,1)'; % we map the weights to [0,1] and unit-scale them
% comp1 = comp1/sum(comp1);

virch = comp1' * squeeze(mean(ERPx,1));
plot(t, virch)
ax = gca;
ax.FontSize = 14;
ax.YLim = [-1.5 1.5];
ax.XLim = [-100 300];
vline(0); hline(0); grid on; hold off

subplot(2,3,6)
EEG = pop_loadset(['/Users/RomanKoshkin/Documents/MATLAB/NeuroBarometer/Roma_15jan/Ro1.set']);
EEG.data(ch,:) = comp1' * EEG.data;
ERPproj = plot_e(EEG, ch, 'Projection on comp 1');

eeglab redraw
error('asdasdf')

%%
len = 10;
y = zeros(1, len);
y(1) = 100;
x = randi([200 400],1,len-1);
for i = 2:len
    y(i) = y(i-1) + x(i-1);
end