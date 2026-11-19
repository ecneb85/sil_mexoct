% Build the MEX file once with:
%   mkoctfile --mex pr_controller.c pr_controller_mex.c -o pr_controller_mex

scenario = octave_pr_scenario();
t = scenario.t;

kp = 0.2;
kr = 1.0;
bandwidth_rad_s = 2 * pi * 2;
ymin = -2;
ymax = 2;

controller_output = pr_controller_mex( ...
    scenario.error_signal, scenario.fs, scenario.f0, ...
    bandwidth_rad_s, kp, kr, ymin, ymax);

plot(t, scenario.load_level_pu, "g--", ...
     t, scenario.error_signal, "b", ...
     t, controller_output, "r");
grid on;
xlabel("Time (s)");
ylabel("Per-unit amplitude");
legend("Load demand", "400 Hz load disturbance", "PR controller output");
title("Illustrative aircraft AC load step: 30% to 70%");
