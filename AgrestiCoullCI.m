function [CIlo,CIhi] = AgrestiCoullCI(n_successes, n_trials, alpha)
% in Python it works the same:
% from statsmodels.stats.proportion import proportion_confint
% proportion_confint(25,30,0.05,'agresti_coull')
z = -norminv(alpha/2,0,1);
n_hat = n_trials + z^2;
p_hat = 1/n_hat*(n_successes + (z^2)/2);
CIlo = p_hat - z*sqrt(p_hat/n_hat*(1-p_hat));
CIhi = p_hat + z*sqrt(p_hat/n_hat*(1-p_hat));
end