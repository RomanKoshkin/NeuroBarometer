ds_ids = unique({EEG.event.dataset})'; ds_ids(1) = [];

alpha_pow = zeros(11,50);
for k = 1:2%length(ds_ids)
    ds_of_interest = k;
    for text = 1:50
        ds_idx_tmp = ismember({EEG.event.dataset}, ds_ids(ds_of_interest)) &...
            ismember({EEG.event.type}, {num2str(text)});
        latencies = [EEG.event(ds_idx_tmp).latency];
        X = ERPs_1(EEG, latencies);
        tmp = get_alpha_1(EEG, X);
        disp(length(tmp))
        alpha_pow(k,text) = mean(tmp);
    end
end

function [alpha_pow] = get_alpha_1(EEG, X)
    fs = EEG.srate;
    number_of_frequencies = 20;
    chan = 17;

    alpha_pow = zeros(length(X), 1);
  
    for i = 1:length(size(X,1))
        signal = squeeze(X(i,chan,:));
        [pxx,f] = periodogram(signal,[], number_of_frequencies, fs, 'power', 'onesided');
        alpha_pow(i) = pxx(2);
        disp (['Alpha low', num2str(i), ' of ', num2str(length(X))])
    end
end