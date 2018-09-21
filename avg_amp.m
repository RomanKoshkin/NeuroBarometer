% computes average amplitued in the target range.
function [A] = avg_amp(X, chan, t, TR)
sample_nos = find(t>TR(1) & t<=TR(2));
A = mean(X(chan,sample_nos));
end

    