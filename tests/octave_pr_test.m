fs = 10000;
f0 = 50;
t = (0:fs - 1) / fs;
error_signal = sin(2 * pi * f0 * t) + 0.25 * sin(2 * pi * 3 * f0 * t);

output = pr_controller_mex( ...
    error_signal, fs, f0, 2 * pi * 2, 0.2, 1.0, -5, 5);

assert(isequal(size(output), size(error_signal)));
assert(all(isfinite(output(:))));
assert(all(output(:) >= -5 & output(:) <= 5));
assert(any(abs(output(:)) > 1e-6));

saturated_output = pr_controller_mex( ...
    [1, -1, 1, -1], fs, f0, 2 * pi * 2, 100, 0, -0.5, 0.5);
assert(all(saturated_output <= 0.5 & saturated_output >= -0.5));

disp("Octave PR simulation passed.");
