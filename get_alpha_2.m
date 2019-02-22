function [alpha_pow] = get_alpha_2(chan, TR, lat_ids)
    global EEG
    fs = EEG.srate;
    number_of_frequencies = 20;
    alpha_pow = zeros(length(lat_ids),1);
    
    
    latencies = [EEG.event(lat_ids).latency];
    N1 = zeros(length(latencies),1);
    
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
        [pxx,f] = periodogram(tmp(chan,:),[], number_of_frequencies, fs, 'power', 'onesided');
        alpha_pow(i) = pxx(2);
        
    end
end