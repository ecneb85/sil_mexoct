% Build the MEX file once with:
%   mkoctfile --mex pr_controller.c pr_controller_mex.c -o pr_controller_mex

fs = 10000;
f0 = 50;
t = (0:fs - 1) / fs;

% Fundamental plus a third harmonic; the PR controller is tuned to 50 Hz.
error_signal = sin(2 * pi * f0 * t) + 0.25 * sin(2 * pi * 3 * f0 * t);

kp = 0.2;
kr = 1.0;
bandwidth_rad_s = 2 * pi * 2;
ymin = -5;
ymax = 5;

controller_output = pr_controller_mex( ...
    error_signal, fs, f0, bandwidth_rad_s, kp, kr, ymin, ymax);

plot(t, error_signal, t, controller_output);
grid on;
xlabel("Time (s)");
ylabel("Amplitude");
legend("Input error", "PR controller output");
title("Octave PR controller example");
