function [fs] = play_tone(freq, amp, duration)
    fs = 20500;  % sampling frequency
    times = 0:1/fs:duration;
    tone = amp * sin(2*pi * freq * times);
    sound(tone, fs)
end