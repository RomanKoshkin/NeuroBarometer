function [latency] = chk_latency(latency,t,X,chan)

if length(latency) > 1
    idx_x = find(ismember(t, latency));
    val_x = X(chan,idx_x);
    [~, loc_x] = max(abs(val_x));
    latency = t(idx_x(loc_x));
end

end