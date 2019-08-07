function [gaussian] = gausswin(fs, lo, hi, sigma, mu)
    t = -0.1:1/fs:0.3-1/fs;
    gaussian = 1/(sigma*sqrt(2*pi))*exp(-(t-mu).^2/(2*sigma^2));
    gaussian = gaussian / sum (gaussian);       % normalize
    gaussian = abs(1 - gaussian / max(gaussian)); % raise the peak to 1
end