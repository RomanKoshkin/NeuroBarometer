% computes average amplitued in the target range.
function [A] = avg_amp_all(X, chan, t, TR)
A = squeeze(mean(X(:,chan,TR),3));
end

    