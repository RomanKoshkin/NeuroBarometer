clear a_accuracy u_accuracy S mu_Ratt mu_Runatt

%% define model parameters:
LAMBDA = 0.05;
% shift_sec = [-2 -1.75 -1.5 -1.25 -1 -0.75 -0.5 -0.25 -0.125 0 0.125 0.25 0.5 0.75 1]; % vector of stimulus shifts
shift_sec = [-1.25 -1 -0.75 -0.5 -0.25 -0.125 0 0.125 0.25 0.5]; % vector of stimulus shifts
compute_envelope = 1

for sh = 1:length(shift_sec)
    % lags start and end:
    or = 0;    % kernel origin, ms
    en = [100]; % kernel end, ms (here you can add a vector of ends, getting different kernel lengths)
    events = 5:64; % event ordinal numbers in the 

    %% internals:
    S = struct('type', '?');
    ch_left = find(ismember({EEG.chanlocs.labels}, 'Left_AUX') == 1);
    ch_right = find(ismember({EEG.chanlocs.labels},'Right_AUX') == 1);
    Fs = EEG.srate;

    for i = 1:length(en)
        g_att = [];         % attended decoder tensor
        g_unatt = [];       % unattended decoder tensor
        
        S(1).type = EEG.event(1).type;
        counter = 0;
        for j = events     
                        
            if strcmp(EEG.event(j).type, 'L_Lef_on') == 1 
                counter = counter + 1;
                S(counter).type = 'left';
                S(counter).code_no = j;
                
            end
            if strcmp(EEG.event(j).type, 'L_Rig_on') == 1
                counter = counter + 1;
                S(counter).type = 'right';
                S(counter).code_no = j;
            end
            
            if strcmp(EEG.event(j).type, 'other') == 1
                continue
            end
            
            if strcmp(EEG.event(j).type, 'L_Lef_off') == 1
                continue
            end
            
            if strcmp(EEG.event(j).type, 'L_Rig_off') == 1
                continue
            end

            start = round(EEG.event(j).latency);
            fin = round(EEG.event(j+1).latency);
            
            
            if compute_envelope == 1
                stimLeft = abs(hilbert(EEG.data(ch_left, start:fin)))';
                stimRight = abs(hilbert(EEG.data(ch_right, start:fin)))';
            else
                stimLeft = EEG.data(ch_left, start:fin)';
                stimRight = EEG.data(ch_right, start:fin)';
            end
            
            response = EEG.data(1:60, start:fin)';

            [wLeft,t, Lcon] = mTRFtrain(stimLeft, response, Fs, 1, or, en(i), LAMBDA);
            if strcmp (S(counter).type,'left') == 1
                g_att = cat(3, g_att, wLeft);
            else
                g_unatt = cat(3, g_unatt, wLeft);
            end


            [wRight,t, Lcon] = mTRFtrain(stimRight, response, Fs, 1, or, en(i), LAMBDA);
                if strcmp (S(counter).type, 'right') == 1
                g_att = cat(3, g_att, wRight);
            else
                g_unatt = cat(3, g_unatt, wRight);
                end

            % report progress:
            disp(['Computing decoder from trial:' num2str(j)...
                '        Shift: ' num2str(shift_sec(sh)) ' seconds'...
                        ' Kernel length: ' num2str(en(i))])

        end

        % average the decoder over all the 30-second-long trials:
        g_att = mean(g_att,3);
        g_unatt = mean(g_unatt,3);

        counter = 0
        for j = [S.code_no]
            counter = counter + 1;

            start = round(EEG.event(j).latency);
            fin = round(EEG.event(j+1).latency);
            
            if compute_envelope == 1
                stimLeft = abs(hilbert(EEG.data(ch_left, start:fin)))';
                stimRight = abs(hilbert(EEG.data(ch_right, start:fin)))';
            else
                stimLeft = EEG.data(ch_left, start:fin)';
                stimRight = EEG.data(ch_right, start:fin)';
            end
            
            stimLeft = circshift(stimLeft, Fs*shift_sec(sh));
            stimRight = circshift(stimRight, Fs*shift_sec(sh));
            
            response = EEG.data(1:60, start:fin)';



            [recon,S(counter).a_r_left,p,MSE] = mTRFpredict(stimLeft, response, g_att, Fs, 1, or, en(i), Lcon);
            [recon,S(counter).a_r_right,p,MSE] = mTRFpredict(stimRight, response, g_att, Fs, 1, or, en(i), Lcon);

            [recon,S(counter).u_r_left,p,MSE] = mTRFpredict(stimLeft, response, g_unatt, Fs, 1, or, en(i), Lcon);
            [recon,S(counter).u_r_right,p,MSE] = mTRFpredict(stimRight, response, g_unatt, Fs, 1, or, en(i), Lcon);

        end

        for j = 1:length(S)
            if strcmp(S(j).type,'left') == 1 & S(j).a_r_left > S(j).a_r_right...
                    ||...
                    strcmp(S(j).type,'right') == 1 & S(j).a_r_left < S(j).a_r_right
                S(j).a_correct = 1;
            else
                S(j).a_correct = 0;
            end
        end
        for j = 1:length(S)
            if strcmp(S(j).type,'left') == 1 & S(j).u_r_left > S(j).u_r_right...
                    ||...
                    strcmp(S(j).type,'right') == 1 & S(j).u_r_left < S(j).u_r_right
                S(j).u_correct = 1;
            else
                S(j).u_correct = 0;
            end
        end
        a_accuracy(i,sh) = mean([S(1:length(S)).a_correct]);
        u_accuracy(i,sh) = mean([S(1:length(S)).u_correct]);

        for j = 1:length(S)
            if strcmp(S(j).type,'right') == 1
                S(j).a_r_att = S(j).a_r_right;
                S(j).a_r_unatt = S(j).a_r_left;
            else
                S(j).a_r_att = S(j).a_r_left;
                S(j).a_r_unatt = S(j).a_r_right;
            end
        end

        for j = 1:length(S)
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
        scatter([S.a_r_att], [S.a_r_unatt])
        ax = gca; ax.FontSize = 14;
        title (['ATTended decoder accuracy ' num2str(a_accuracy(i,sh)) ', shift = ' num2str(shift_sec(sh))])
        xlabel ('r_{attended}', 'FontSize', 20)
        ylabel ('r_{unattended}', 'FontSize', 20)
        grid on
        refline(1,0)
        pbaspect([1 1 1])
        ax.YLim = [-0.1 0.25];
        ax.XLim = [-0.1 0.25];

        subplot(1,2,2)
        scatter([S.u_r_att], [S.u_r_unatt])
        ax = gca; ax.FontSize = 14;
        title (['UNattended decoder accuracy ' num2str(u_accuracy(i,sh)) ', shift = ' num2str(shift_sec(sh))])
        xlabel ('r_{attended}', 'FontSize', 20)
        ylabel ('r_{unattended}', 'FontSize', 20)
        grid on
        refline(1,0)
        pbaspect([1 1 1])
        ax.YLim = [-0.1 0.25];
        ax.XLim = [-0.1 0.25];
        mu_Ratt(sh) = mean([S.a_r_att]);
        mu_Runatt(sh) = mean([S.u_r_att]);
    end
end

%%
figure
subplot(1,2,1)
plot(1:length(shift_sec), a_accuracy, 1:length(shift_sec), u_accuracy, 'LineWidth', 3)
ax = gca;
ax.XTick = 1:length(shift_sec);
ax.XTickLabels = {shift_sec};
title(['Unfiltered/Unreferenced, Kernel = ' num2str(en(i)) ' \lambda = ' num2str(LAMBDA)], 'FontSize', 14)
legend({'attended accuracy', 'unattended accuracy'}, 'FontSize', 12)
ylabel ('Classification accuracy', 'FontSize', 16)
xlabel ('Stimulus shift relative to real time', 'FontSize', 16)
grid on

subplot(1,2,2)
plot(1:length(shift_sec), mu_Ratt, 1:length(shift_sec), mu_Runatt, 'LineWidth', 3)
ax = gca;
ax.XTick = 1:length(shift_sec);
ax.XTickLabels = {shift_sec};
title(['Correlation vs. Time Shift, Kernel = ' num2str(en(i)) ' \lambda = ' num2str(LAMBDA)], 'FontSize', 14)
legend({'R_{attended}', 'R_{unattended}'}, 'FontSize', 12)
ylabel ('Pearsons R', 'FontSize', 16)
xlabel ('Stimulus shift relative to real time', 'FontSize', 16)
grid on