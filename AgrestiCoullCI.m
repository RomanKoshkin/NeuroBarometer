function [CIlo,CIhi] = AgrestiCoullCI(n_successes, n_trials, alpha)
% in Python it works the same:
% from statsmodels.stats.proportion import proportion_confint
% proportion_confint(25,30,0.05,'agresti_coull')

% to understand 
% in R:
% binom.test(c(50, 50), p = 0.5)

% number of successes = 50, number of trials = 100, p-value = 1
% alternative hypothesis: true probability of success is not equal to 0.5
% 95 percent confidence interval:
%  0.3983211 0.6016789
% sample estimates:
% probability of success 0.5 
% INTERPRETATION:
% if the confidence interval overlaps with the hypothetical probability
% (0.5), then we don't the observed proportion of successes is not
% significantly different from what we expect to see.
% if the CI doesn't include the expected probability, then we have a
% significant difference between the expected and observed (alternative
% hypothesis is true)

z = -norminv(alpha/2,0,1);
n_hat = n_trials + z^2;
p_hat = 1/n_hat*(n_successes + (z^2)/2);
CIlo = p_hat - z*sqrt(p_hat/n_hat*(1-p_hat));
CIhi = p_hat + z*sqrt(p_hat/n_hat*(1-p_hat));
end