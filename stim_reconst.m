clear a_accuracy u_accuracy

%% define model parameters:
LAMBDA = 1e5;
shift_sec = [-0.5 -0.25 0 0.25 0.5]; % vector of stimulus shifts

for sh = 1:length(shift_sec)
    % lags start and end:
    or = 0;
    en = [500] % Vector of kernel lengths for testing

    %% internals:
    S = struct('type', '?');
    ch_left = find(ismember({EEG.chanlocs.labels}, 'Left_AUX') == 1);
    ch_right = find(ismember({EEG.chanlocs.labels}, 'Right_AUX') == 1);
    Fs = EEG.srate;

    for i = 1:length(en)
        g_att = [];         % attended decoder tensor
        g_unatt = [];       % unattended decoder tensor
        
        for j = 11:24       % 30-second-long trials from 11 to 24 (S3, S4)

            S(j).type = EEG.event(j).type;
            if mod(j,2)==0 
                S(j).type = 'left';
            else
                S(j).type = 'right';
            end

            start = round(EEG.event(j).latency);
            fin = round(EEG.event(j+1).latency);

            stimLeft = abs(hilbert(EEG.data(ch_left, start:fin)))';
            stimRight = abs(hilbert(EEG.data(ch_right, start:fin)))';
            response = EEG.data(1:60, start:fin)';

            [wLeft,t, Lcon] = mTRFtrain(stimLeft, response, Fs, 1, or, en(i), LAMBDA);
            if strcmp (S(j).type,'left') == 1
                g_att = cat(3, g_att, wLeft);
            else
                g_unatt = cat(3, g_unatt, wLeft);
            end


            [wRight,t, Lcon] = mTRFtrain(stimRight, response, Fs, 1, or, en(i), LAMBDA);
                if strcmp (S(j).type, 'right') == 1
                g_att = cat(3, g_att, wRight);
            else
                g_unatt = cat(3, g_unatt, wRight);
                end

            % report progress:
            ['Computing decoder from trial:' num2str(j)...
                '        Shift: ' num2str(shift_sec(sh))]

        end

        % average the decoder over all the 30-second-long trials:
        g_att = mean(g_att,3);
        g_unatt = mean(g_unatt,3);

        for j = 11:24

            start = round(EEG.event(j).latency);
            fin = round(EEG.event(j+1).latency);

            stimLeft = abs(hilbert(EEG.data(ch_left, start:fin)))';
            stimLeft = circshift(stimLeft, Fs*shift_sec(sh));
            stimRight = abs(hilbert(EEG.data(ch_right, start:fin)))';
            stimRight = circshift(stimRight, Fs*shift_sec(sh));
            response = EEG.data(1:60, start:fin)';



                    [recon,S(j).a_r_left,p,MSE] = mTRFpredict(stimLeft, response, g_att, Fs, 1, or, en(i), Lcon);
                    [recon,S(j).a_r_right,p,MSE] = mTRFpredict(stimRight, response, g_att, Fs, 1, or, en(i), Lcon);

                    [recon,S(j).u_r_left,p,MSE] = mTRFpredict(stimLeft, response, g_unatt, Fs, 1, or, en(i), Lcon);
                    [recon,S(j).u_r_right,p,MSE] = mTRFpredict(stimRight, response, g_unatt, Fs, 1, or, en(i), Lcon);

        end

        for j = 11:24
            if strcmp(S(j).type,'left') == 1 & S(j).a_r_left > S(j).a_r_right...
                    ||...
                    strcmp(S(j).type,'right') == 1 & S(j).a_r_left < S(j).a_r_right
                S(j).a_correct = 1;
            else
                S(j).a_correct = 0;
            end
        end
        for j = 11:24
            if strcmp(S(j).type,'left') == 1 & S(j).u_r_left > S(j).u_r_right...
                    ||...
                    strcmp(S(j).type,'right') == 1 & S(j).u_r_left < S(j).u_r_right
                S(j).u_correct = 1;
            else
                S(j).u_correct = 0;
            end
        end
        a_accuracy(i,sh) = mean([S(11:24).a_correct]);
        u_accuracy(i,sh) = mean([S(11:24).u_correct]);

        for j = 11:24
            if strcmp(S(j).type,'right') == 1
                S(j).a_r_att = S(j).a_r_right;
                S(j).a_r_unatt = S(j).a_r_left;
            else
                S(j).a_r_att = S(j).a_r_left;
                S(j).a_r_unatt = S(j).a_r_right;
            end
        end

        for j = 11:24
            if strcmp(S(j).type,'right') == 1
                S(j).u_r_att = S(j).u_r_right;
                S(j).u_r_unatt = S(j).u_r_left;
            else
                S(j).u_r_att = S(j).u_r_left;
                S(j).u_r_unatt = S(j).u_r_right;
            end
        end

        figure
        subplot(1,2,1)
        scatter([S(11:24).a_r_att], [S(11:24).a_r_unatt])
        ax = gca; ax.FontSize = 14;
        title (['attended decoder, ' num2str(a_accuracy(i,sh))])
        xlabel ('r_{attended}', 'FontSize', 20)
        ylabel ('r_{unattended}', 'FontSize', 20)
        grid on
        refline(1,0)
        pbaspect([1 1 1])
        ax.YLim = [-0.1 0.25];
        ax.XLim = [-0.1 0.25];

        subplot(1,2,2)
        scatter([S(11:24).u_r_att], [S(11:24).u_r_unatt])
        ax = gca; ax.FontSize = 14;
        title (['UNattended decoder, ' num2str(u_accuracy(i,sh))])
        xlabel ('r_{attended}', 'FontSize', 20)
        ylabel ('r_{unattended}', 'FontSize', 20)
        grid on
        refline(1,0)
        pbaspect([1 1 1])
        ax.YLim = [-0.1 0.25];
        ax.XLim = [-0.1 0.25];
    end
end

figure
plot(1:length(shift_sec), a_accuracy, 1:length(shift_sec), u_accuracy, 'LineWidth', 3)
ax = gca;
ax.XTickLabels = {shift_sec};
title ('Accuracy of decoders as a functio of stimulus shift, sec','FontSize', 12)
legend({'attended accuracy', 'unattended accuracy'}, 'FontSize', 12)
ylabel ('Classification accuracy', 'FontSize', 16)
xlabel ('Stimulus shift relative to real time', 'FontSize', 16)