function scenario = octave_pr_scenario()
scenario.fs = 10000;
scenario.f0 = 400;
scenario.t = (0:scenario.fs - 1) / scenario.fs;
scenario.nominal_voltage_rms_v = 115;
scenario.load_step_time_s = 0.5;
scenario.load_before_pu = 0.3;
scenario.load_after_pu = 0.7;
scenario.load_level_pu = scenario.load_before_pu * ones(size(scenario.t));
scenario.load_level_pu(scenario.t >= scenario.load_step_time_s) = ...
    scenario.load_after_pu;
scenario.error_signal = scenario.load_level_pu .* ...
    (sin(2 * pi * scenario.f0 * scenario.t) + ...
     0.25 * sin(2 * pi * 3 * scenario.f0 * scenario.t));
end
