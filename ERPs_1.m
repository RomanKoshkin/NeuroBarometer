function [X] = ERPs_1(EEG, latencies)
    % initialize empty matrix of the right size:
    start = round(latencies(3)-round(0.1*EEG.srate));
    fin = round(latencies(3)+round(0.5*EEG.srate));
    tmp = EEG.data(:,start:fin);
    X = zeros(length(latencies), size(tmp,1), size(tmp, 2));

    c = 1;

    M = eye(size(tmp,1));
    for i = latencies
        start = round(i-round(0.1*EEG.srate));
        if start<1
            continue
        end
        fin = round(i+round(0.5*EEG.srate));
        tmp = M * EEG.data(:,start:fin);
        disp(['iteration ', num2str(c), ' of ', num2str(length(latencies))])
        % baseline correction:
        baseline = mean(tmp(:,1:21),2);
        tmp = tmp - baseline;

        X(c,:,:) = tmp;
        c = c + 1;
    end
    
end