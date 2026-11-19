function output = octave_pr_reference(input, fs, f0, bandwidth_rad_s, kp, kr, ymin, ymax)
two_fs = 2 * fs;
omega = 2 * pi * f0;
damping = 2 * bandwidth_rad_s;
omega_squared = omega ^ 2;
denominator = two_fs ^ 2 + damping * two_fs + omega_squared;

b0 = kr * damping * two_fs / denominator;
b2 = -b0;
a1 = (-2 * two_fs ^ 2 + 2 * omega_squared) / denominator;
a2 = (two_fs ^ 2 - damping * two_fs + omega_squared) / denominator;

output = zeros(size(input));
x1 = 0;
x2 = 0;
y1 = 0;
y2 = 0;

for sample_index = 1:numel(input)
    resonant_output = b0 * input(sample_index) + b2 * x2 - ...
        a1 * y1 - a2 * y2;
    result = kp * input(sample_index) + resonant_output;

    x2 = x1;
    x1 = input(sample_index);
    y2 = y1;
    y1 = resonant_output;

    output(sample_index) = min(max(result, ymin), ymax);
end
end
