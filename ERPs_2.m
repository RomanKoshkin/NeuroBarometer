function [X, N1, Z] = ERPs_2(chan, TR, lat_ids)
    global EEG
    latencies = [EEG.event(lat_ids).latency];
    N1 = zeros(length(latencies),1);
    
    % initialize empty matrix of the right size:
    start = round(latencies(3)-round(0.1*EEG.srate));
    fin = round(latencies(3)+round(0.5*EEG.srate));
    tmp = EEG.data(:,start:fin);
    X = zeros(size(tmp,1), size(tmp, 2));
    
    Z = zeros(length(lat_ids), size(tmp,2));

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
        
        % find mean N1
        N1_tmp = mean(tmp(chan,TR));

        X(:,:) = X(:,:) + tmp;
        
        EEG.event(lat_ids(i)).N1 = N1_tmp;
        
        N1(i) = N1_tmp;
        Z(i,:) = tmp(chan,:);
    end
    
    % return mean
    X = X/length(latencies);
end