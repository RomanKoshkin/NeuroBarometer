function [alpha_pow] = get_alpha_10(EEG, ch, ad_code)
    fs = EEG.srate;
    number_of_frequencies = 200;
    
    lats = find(ismember([EEG.event.code], ad_code));
    alpha_pow = zeros(length(ch), length(lats));
    
    latencies = [EEG.event(lats).latency];
    
    % initialize empty matrix of the right size:
    start = round(latencies(3)-round(0.1*EEG.srate));
    fin = round(latencies(3)+round(0.5*EEG.srate));
    tmp = EEG.data(:,start:fin);
    
    for i = 1:length(latencies)
        start = round(latencies(i)-round(0.1*EEG.srate));
        if start<1
            continue
        end
        fin = round(latencies(i)+round(0.5*EEG.srate));
        tmp = EEG.data(:,start:fin);
        disp(['iteration ', num2str(i), ' of ', num2str(length(latencies))])
        % baseline correction:
        baseline = mean(tmp(:,1:21),2);
        tmp = tmp - baseline;
        c = 0;
        for j = ch
            c = c + 1;
            [pxx,f] = periodogram(tmp(j,:),[], number_of_frequencies, fs, 'power', 'onesided');
            alpha_pow(c, i) = mean(pxx(9:13));
        end
    end
%     alpha_pow = remove_outliers(alpha_pow, 4);
end

function [alpha_z] = remove_outliers(alpha_pow, threshold)
    se = std(alpha_pow')'./sqrt(size(alpha_pow,2));
    z = (alpha_pow-mean(alpha_pow,2))./se;
    alpha_z = alpha_pow(:, abs(z(1,:)) < threshold);
end