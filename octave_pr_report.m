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

if ~all(isfinite(controller_output(:)))
    error("Simulation produced a non-finite output.");
end

reference_output = octave_pr_reference( ...
    scenario.error_signal, scenario.fs, scenario.f0, ...
    bandwidth_rad_s, kp, kr, ymin, ymax);
output_difference = controller_output(:) - reference_output(:);
max_abs_error = max(abs(output_difference));
rms_error = sqrt(mean(output_difference .^ 2));
reference_peak = max(abs(reference_output(:)));
relative_max_error_percent = 100 * max_abs_error / max(reference_peak, eps);
controller_peak = max(abs(controller_output(:)));
controller_rms = sqrt(mean(controller_output(:) .^ 2));
input_rms = sqrt(mean(scenario.error_signal(:) .^ 2));
saturated_samples = sum(controller_output(:) <= ymin | ...
    controller_output(:) >= ymax);
saturation_percent = 100 * saturated_samples / numel(controller_output);

before_step = scenario.t >= 0.25 & scenario.t < 0.45;
after_step = scenario.t >= 0.65 & scenario.t < 0.85;
before_step_rms = sqrt(mean(controller_output(before_step) .^ 2));
after_step_rms = sqrt(mean(controller_output(after_step) .^ 2));

two_fs = 2 * scenario.fs;
omega = 2 * pi * scenario.f0;
damping = 2 * bandwidth_rad_s;
omega_squared = omega ^ 2;
coefficient_denominator = two_fs ^ 2 + ...
    damping * two_fs + omega_squared;
b0 = kr * damping * two_fs / coefficient_denominator;
a1 = (-2 * two_fs ^ 2 + 2 * omega_squared) / coefficient_denominator;
a2 = (two_fs ^ 2 - damping * two_fs + omega_squared) / ...
    coefficient_denominator;
z1 = exp(-1i * 2 * pi * scenario.f0 / scenario.fs);
response_at_resonance = kp + ...
    (b0 - b0 * z1 ^ 2) / (1 + a1 * z1 + a2 * z1 ^ 2);
resonance_gain = abs(response_at_resonance);
resonance_phase_degrees = angle(response_at_resonance) * 180 / pi;

report_directory = fullfile(pwd, "artifacts");
if exist(report_directory, "dir") ~= 7
    [created, message] = mkdir(report_directory);
    if ~created
        error("Unable to create report directory: %s", message);
    end
end

report_path = fullfile(report_directory, "pr_simulation_report.html");
report_file = fopen(report_path, "w");
if report_file < 0
    error("Unable to open report file: %s", report_path);
end

plot_left = 90;
plot_top = 40;
plot_width = 860;
plot_height = 330;
plot_ymin = -2;
plot_ymax = 2;
sample_indices = round(linspace(1, numel(t), 1200));

fprintf(report_file, "<!doctype html>\n");
fprintf(report_file, '<html lang="en">\n<head>\n');
fprintf(report_file, '<meta charset="utf-8">\n');
fprintf(report_file, '<meta name="viewport" content="width=device-width, initial-scale=1">\n');
fprintf(report_file, "<title>PR filter simulation report</title>\n");
fprintf(report_file, "<style>\n");
fprintf(report_file, "body{font:16px system-ui,sans-serif;margin:2rem auto;max-width:1100px;padding:0 1rem;color:#172033;background:#f8fafc}\n");
fprintf(report_file, "h1{font-size:1.8rem} .card{background:white;border:1px solid #dbe2ea;border-radius:12px;padding:1rem 1.25rem;margin:1rem 0}\n");
fprintf(report_file, "svg{width:100%%;height:auto} table{border-collapse:collapse} th,td{text-align:left;padding:.45rem 1.5rem .45rem 0}\n");
fprintf(report_file, ".load{stroke:#16a34a;stroke-dasharray:6 4}.input{stroke:#2563eb}.output{stroke:#e11d48}.legend{font-size:14px}\n");
fprintf(report_file, ".chart-controls{display:flex;align-items:center;gap:.5rem;flex-wrap:wrap;margin:.5rem 0}.chart-controls button{padding:.45rem .8rem;border:1px solid #cbd5e1;border-radius:6px;background:#fff;cursor:pointer}.chart-hint{color:#475569;font-size:.9rem}\n");
fprintf(report_file, "#response-chart{touch-action:none;cursor:grab}#response-chart:active{cursor:grabbing}\n");
fprintf(report_file, "</style>\n</head>\n<body>\n");
fprintf(report_file, "<h1>PR filter simulation report</h1>\n");
fprintf(report_file, ...
    ['<p>Illustrative 115 V RMS, 400 Hz aircraft AC-bus scenario; ' ...
     'not a validated aircraft power-system model.</p>\n']);
fprintf(report_file, '<section class="card"><h2>Simulation settings</h2><table>\n');
fprintf(report_file, "<tr><th>Nominal AC bus</th><td>%g V RMS</td></tr>\n", ...
    scenario.nominal_voltage_rms_v);
fprintf(report_file, "<tr><th>Sample rate</th><td>%g Hz</td></tr>\n", scenario.fs);
fprintf(report_file, "<tr><th>Sample interval</th><td>%.6g ms</td></tr>\n", ...
    1000 / scenario.fs);
fprintf(report_file, "<tr><th>Nyquist frequency</th><td>%g Hz</td></tr>\n", ...
    scenario.fs / 2);
fprintf(report_file, "<tr><th>Resonant frequency</th><td>%g Hz</td></tr>\n", ...
    scenario.f0);
fprintf(report_file, ...
    "<tr><th>Load step</th><td>%g to %g p.u. at %.2f s</td></tr>\n", ...
    scenario.load_before_pu, scenario.load_after_pu, ...
    scenario.load_step_time_s);
fprintf(report_file, "<tr><th>Bandwidth</th><td>%.3f rad/s (%.3f Hz)</td></tr>\n", ...
    bandwidth_rad_s, bandwidth_rad_s / (2 * pi));
fprintf(report_file, "<tr><th>Kp / Kr</th><td>%g / %g</td></tr>\n", kp, kr);
fprintf(report_file, "<tr><th>Output limits</th><td>[%g, %g]</td></tr>\n", ymin, ymax);
fprintf(report_file, "</table></section>\n");

fprintf(report_file, '<section class="card"><h2>Load step and controller response</h2>\n');
fprintf(report_file, '<div class="chart-controls" role="group" aria-label="Graph zoom controls">\n');
fprintf(report_file, '<button id="zoom-in" type="button" aria-label="Zoom in">+</button>\n');
fprintf(report_file, '<button id="zoom-out" type="button" aria-label="Zoom out">-</button>\n');
fprintf(report_file, '<button id="zoom-reset" type="button">Reset zoom</button>\n');
fprintf(report_file, '<span class="chart-hint">Use the mouse wheel to zoom and drag to pan.</span>\n');
fprintf(report_file, '</div>\n');
fprintf(report_file, '<svg id="response-chart" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 470" role="img" aria-labelledby="chart-title chart-desc">\n');
fprintf(report_file, '<title id="chart-title">400 Hz load step and PR controller response</title>\n');
fprintf(report_file, ...
    ['<desc id="chart-desc">Load demand steps from 0.3 to 0.7 per unit ' ...
     'at 0.5 seconds, with the input disturbance and controller output.</desc>\n']);
fprintf(report_file, '<defs><clipPath id="plot-clip"><rect x="%g" y="%g" width="%g" height="%g"/></clipPath></defs>\n', ...
    plot_left, plot_top, plot_width, plot_height);
fprintf(report_file, '<g id="plot-content" clip-path="url(#plot-clip)">\n');

for y_tick = plot_ymin:1:plot_ymax
    y_position = plot_top + ...
        (plot_ymax - y_tick) / (plot_ymax - plot_ymin) * plot_height;
    fprintf(report_file, ...
        '<line x1="%g" y1="%g" x2="%g" y2="%g" stroke="#e2e8f0"/>\n', ...
        plot_left, y_position, plot_left + plot_width, y_position);
    fprintf(report_file, ...
        '<text x="%g" y="%g" text-anchor="end" font-size="12" fill="#475569">%g</text>\n', ...
        plot_left - 10, y_position + 4, y_tick);
end

for x_tick = 0:0.2:1
    x_position = plot_left + x_tick * plot_width;
    fprintf(report_file, ...
        '<line x1="%g" y1="%g" x2="%g" y2="%g" stroke="#e2e8f0"/>\n', ...
        x_position, plot_top, x_position, plot_top + plot_height);
    fprintf(report_file, ...
        '<text x="%g" y="%g" text-anchor="middle" font-size="12" fill="#475569">%.1f</text>\n', ...
        x_position, plot_top + plot_height + 20, x_tick);
end

fprintf(report_file, ...
    '<line x1="%g" y1="%g" x2="%g" y2="%g" stroke="#64748b"/>\n', ...
    plot_left, plot_top, plot_left, plot_top + plot_height);
fprintf(report_file, ...
    '<line x1="%g" y1="%g" x2="%g" y2="%g" stroke="#64748b"/>\n', ...
    plot_left, plot_top + plot_height, plot_left + plot_width, plot_top + plot_height);

fprintf(report_file, ...
    '<polyline class="input" fill="none" stroke-width="1.5" points="');
for sample_index = sample_indices
    x_position = plot_left + t(sample_index) / t(end) * plot_width;
    y_position = plot_top + ...
        (plot_ymax - scenario.error_signal(sample_index)) / ...
        (plot_ymax - plot_ymin) * plot_height;
    fprintf(report_file, "%.2f,%.2f ", x_position, y_position);
end
fprintf(report_file, '"/>\n');

fprintf(report_file, ...
    '<polyline class="load" fill="none" stroke-width="2" points="');
for sample_index = sample_indices
    x_position = plot_left + t(sample_index) / t(end) * plot_width;
    y_position = plot_top + ...
        (plot_ymax - scenario.load_level_pu(sample_index)) / ...
        (plot_ymax - plot_ymin) * plot_height;
    fprintf(report_file, "%.2f,%.2f ", x_position, y_position);
end
fprintf(report_file, '"/>\n');

fprintf(report_file, ...
    '<polyline class="output" fill="none" stroke-width="1.5" points="');
for sample_index = sample_indices
    x_position = plot_left + t(sample_index) / t(end) * plot_width;
    y_position = plot_top + ...
        (plot_ymax - controller_output(sample_index)) / ...
        (plot_ymax - plot_ymin) * plot_height;
    fprintf(report_file, "%.2f,%.2f ", x_position, y_position);
end
fprintf(report_file, '"/>\n');
fprintf(report_file, "</g>\n");

fprintf(report_file, ...
    '<text x="%g" y="%g" text-anchor="middle" font-size="13" fill="#334155">Time (s)</text>\n', ...
    plot_left + plot_width / 2, plot_top + plot_height + 48);
fprintf(report_file, ...
    '<text x="20" y="%g" text-anchor="middle" font-size="13" fill="#334155" transform="rotate(-90 20 %g)">Per-unit amplitude</text>\n', ...
    plot_top + plot_height / 2, plot_top + plot_height / 2);
fprintf(report_file, ...
    '<line x1="200" y1="445" x2="230" y2="445" class="load" stroke-width="2"/>\n');
fprintf(report_file, ...
    '<text x="238" y="450" class="legend" fill="#334155">Load demand (p.u.)</text>\n');
fprintf(report_file, ...
    '<line x1="450" y1="445" x2="480" y2="445" class="input" stroke-width="2"/>\n');
fprintf(report_file, ...
    '<text x="488" y="450" class="legend" fill="#334155">Input disturbance</text>\n');
fprintf(report_file, ...
    '<line x1="680" y1="445" x2="710" y2="445" class="output" stroke-width="2"/>\n');
fprintf(report_file, ...
    '<text x="718" y="450" class="legend" fill="#334155">PR output</text>\n');
fprintf(report_file, "</svg></section>\n");

fprintf(report_file, "<script>\n");
fprintf(report_file, "(() => {\n");
fprintf(report_file, "const svg = document.getElementById('response-chart');\n");
fprintf(report_file, "const plot = document.getElementById('plot-content');\n");
fprintf(report_file, "let scale = 1, tx = 0, ty = 0, dragStart = null;\n");
fprintf(report_file, "const limits = {left: %g, top: %g, width: %g, height: %g};\n", ...
    plot_left, plot_top, plot_width, plot_height);
fprintf(report_file, "function point(event) { const p = svg.createSVGPoint(); p.x = event.clientX; p.y = event.clientY; return p.matrixTransform(svg.getScreenCTM().inverse()); }\n");
fprintf(report_file, "function applyTransform() { plot.setAttribute('transform', `translate(${tx} ${ty}) scale(${scale})`); }\n");
fprintf(report_file, "function clampPan() { const minX = limits.left + limits.width - scale * (limits.left + limits.width); const maxX = limits.left - scale * limits.left; const minY = limits.top + limits.height - scale * (limits.top + limits.height); const maxY = limits.top - scale * limits.top; tx = Math.min(maxX, Math.max(minX, tx)); ty = Math.min(maxY, Math.max(minY, ty)); }\n");
fprintf(report_file, "function zoomAt(factor, x, y) { const next = Math.max(1, Math.min(16, scale * factor)); const ratio = next / scale; tx = x - (x - tx) * ratio; ty = y - (y - ty) * ratio; scale = next; clampPan(); applyTransform(); }\n");
fprintf(report_file, "document.getElementById('zoom-in').addEventListener('click', () => zoomAt(1.25, 500, 235));\n");
fprintf(report_file, "document.getElementById('zoom-out').addEventListener('click', () => zoomAt(0.8, 500, 235));\n");
fprintf(report_file, "document.getElementById('zoom-reset').addEventListener('click', () => { scale = 1; tx = 0; ty = 0; applyTransform(); });\n");
fprintf(report_file, "svg.addEventListener('wheel', event => { event.preventDefault(); const p = point(event); zoomAt(event.deltaY < 0 ? 1.15 : 1 / 1.15, p.x, p.y); }, {passive: false});\n");
fprintf(report_file, "svg.addEventListener('pointerdown', event => { if (event.button !== 0 || scale <= 1) return; const p = point(event); dragStart = {x: p.x, y: p.y, tx, ty}; svg.setPointerCapture(event.pointerId); });\n");
fprintf(report_file, "svg.addEventListener('pointermove', event => { if (!dragStart) return; const p = point(event); tx = dragStart.tx + p.x - dragStart.x; ty = dragStart.ty + p.y - dragStart.y; clampPan(); applyTransform(); });\n");
fprintf(report_file, "svg.addEventListener('pointerup', () => { dragStart = null; });\n");
fprintf(report_file, "svg.addEventListener('pointercancel', () => { dragStart = null; });\n");
fprintf(report_file, "})();\n");
fprintf(report_file, "</script>\n");

fprintf(report_file, '<section class="card"><h2>Filter quality and output metrics</h2><table>\n');
fprintf(report_file, "<tr><th>Peak absolute output</th><td>%.6g p.u.</td></tr>\n", ...
    controller_peak);
fprintf(report_file, "<tr><th>RMS output</th><td>%.6g p.u.</td></tr>\n", ...
    controller_rms);
fprintf(report_file, "<tr><th>Input RMS</th><td>%.6g p.u.</td></tr>\n", input_rms);
fprintf(report_file, "<tr><th>Max absolute error vs double reference</th><td>%.6g p.u.</td></tr>\n", ...
    max_abs_error);
fprintf(report_file, "<tr><th>RMS error vs double reference</th><td>%.6g p.u.</td></tr>\n", ...
    rms_error);
fprintf(report_file, "<tr><th>Max error relative to reference peak</th><td>%.6g %%</td></tr>\n", ...
    relative_max_error_percent);
fprintf(report_file, "<tr><th>Controller gain at resonance</th><td>%.6g</td></tr>\n", ...
    resonance_gain);
fprintf(report_file, "<tr><th>Controller phase at resonance</th><td>%.6g degrees</td></tr>\n", ...
    resonance_phase_degrees);
fprintf(report_file, "<tr><th>Samples at output limit</th><td>%d (%.4g %%)</td></tr>\n", ...
    saturated_samples, saturation_percent);
fprintf(report_file, "<tr><th>Output RMS before load step</th><td>%.6g p.u.</td></tr>\n", ...
    before_step_rms);
fprintf(report_file, "<tr><th>Output RMS after load step</th><td>%.6g p.u.</td></tr>\n", ...
    after_step_rms);
fprintf(report_file, "<tr><th>Samples / duration</th><td>%d / %.3g s</td></tr>\n", ...
    numel(t), t(end) + 1 / scenario.fs);
fprintf(report_file, "</table></section>\n");
fprintf(report_file, "</body>\n</html>\n");

if fclose(report_file) ~= 0
    error("Unable to finish writing report file: %s", report_path);
end

fprintf("Generated HTML report: %s\n", report_path);
