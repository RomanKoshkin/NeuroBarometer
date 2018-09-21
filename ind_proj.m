% this script take a 63 channel EEG that is a dataset of merged subjects
% then based on Target Ranges (TR) projects the 63 channels onto the first
% eigenvector INDIVIDUALLY. The projection goes to channel 64.

U_m = zeros(11,63,63);
virt_ch = zeros(1, length(EEG.data));

for k = 1:11
    load('TR_mat.mat')
    t = linspace(-100, 500, 121);
    % TR = [90 200];

    tt = unique({EEG.event.dataset});
    tt(1) = [];
    IDx = zeros(11,2);

    for i = 1:11
        disp(tt{i})
        idx = find(strcmp({EEG.event.dataset}, tt(i)));
        IDx(i,1:2) = [min(idx) max(idx)];
    end


    TR = TR_mat(k,:)
    lat = [EEG.event(IDx(k,1):IDx(k,2)).latency];
    X = ERPs_1(EEG, lat);
    X_m = squeeze(mean(X,1));

    [U,S,V] = svd(X_m);
    figure
    subplot(2,3,1)
    topoplot(U(:,1), EEG.chanlocs,'style','both','electrodes','labelpoint');
    tit = title('Comp.1 (entire ERP)'); tit.FontSize = 14;
    aa = subplot(2,3,[2 3 5 6]);
    plot(t,X_m(17,:)); hline(0); vline(0)
    hold on

    % get the N1 peak latency
    [pks_min, locs_min] = findpeaks(-X_m(17,:), t, 'MinPeakProminence', 0.05);
    pks_min = -pks_min;
    N1_latency = locs_min(locs_min>=TR(1) & locs_min<=TR(2));
    if length(N1_latency) > 1
        idx_x = find(ismember(t, N1_latency));
        val_x = X_m(17,idx_x);
        [~, loc_x] = max(abs(val_x));
        N1_latency = t(idx_x(loc_x));
    end

    text(N1_latency, pks_min(locs_min==N1_latency), 'N1')

    % TR times (40-ms window surrounding the observed peak)
    N1_sample_nos = find(t==N1_latency-20):find(t==N1_latency+20);

    [U,S,V] = svd(X_m(:,N1_sample_nos));
    subplot(2,3,4)
    topoplot(U(:,1), EEG.chanlocs,'style','both','electrodes','labelpoint');
    tit = title(['Comp.1 (TR ', num2str(TR(1)), '-', num2str(TR(2)), ' ms)']); tit.FontSize = 14;
    back_proj = U(:,1)' * X_m;
    flip_signs = mean(back_proj(N1_sample_nos));
    if flip_signs > 0
        U(:,1) = -U(:,1);
        back_proj = U(:,1)' * X_m;
        subplot(2,3,4)
        topoplot(U(:,1), EEG.chanlocs,'style','both','electrodes','labelpoint');
        tit = title(['Comp.1 (TR ', num2str(TR(1)), '-', num2str(TR(2)), ' ms)']); tit.FontSize = 14;
    end
    plot(aa, t, back_proj)

    % highlight the N1 range
    axes(aa);
    S = struct;
    S.Vertices = [N1_latency-20 aa.YLim(1); N1_latency-20 aa.YLim(2); N1_latency+20 aa.YLim(2); N1_latency+20 aa.YLim(1)];
    S.Faces = [1 2 3 4];
    S.EdgeColor = 'none';
    S.FaceAlpha = 0.25;
    patch(S)

    U_m(k,:,:) = U;
    virt_ch(lat(1):lat(end)) = U(:,1)' * EEG.data(1:63,lat(1):lat(end));
end

EEG.data(64,:) = virt_ch;

