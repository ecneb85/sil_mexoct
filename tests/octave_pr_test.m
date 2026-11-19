scenario = octave_pr_scenario();

output = pr_controller_mex( ...
    scenario.error_signal, scenario.fs, scenario.f0, ...
    2 * pi * 2, 0.2, 1.0, -2, 2);

assert(isequal(size(output), size(scenario.error_signal)));
assert(all(isfinite(output(:))));
assert(all(output(:) >= -2 & output(:) <= 2));
assert(any(abs(output(:)) > 1e-6));

before_step = output( ...
    scenario.t >= 0.25 & scenario.t < 0.45);
after_step = output( ...
    scenario.t >= 0.65 & scenario.t < 0.85);
before_step_rms = sqrt(mean(before_step .^ 2));
after_step_rms = sqrt(mean(after_step .^ 2));
assert(after_step_rms > 1.5 * before_step_rms);

saturated_output = pr_controller_mex( ...
    [1, -1, 1, -1], scenario.fs, scenario.f0, ...
    2 * pi * 2, 100, 0, -0.5, 0.5);
assert(all(saturated_output <= 0.5 & saturated_output >= -0.5));

disp("Octave PR load-step simulation passed.");
