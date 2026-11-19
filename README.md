# PR controller example

`pr_controller.c` and `pr_controller.h` contain the controller core in
portable C. The same core can be compiled into STM32 firmware or called from
Octave through the MEX-compatible wrapper in `pr_controller_mex.c`.

The resonant branch implements

```text
Kr * (2 * bandwidth_rad_s * s) /
(s^2 + 2 * bandwidth_rad_s * s + (2*pi*f0)^2)
```

with a Tustin discretization. `Kp` is added as a proportional branch. The
final output is clamped to `[ymin, ymax]`. The MEX wrapper creates a fresh
controller for each call and processes the input vector sequentially.

## Octave

Install Octave and its development/compiler tools, then run these commands
from this directory:

```sh
mkoctfile --mex pr_controller.c pr_controller_mex.c -o pr_controller_mex
octave --quiet octave_pr_demo.m
```

The GitHub Actions workflow builds a Docker image from `Dockerfile` and uses
it to compile the MEX module and run a headless simulation check on every push
and pull request. BuildKit caches the image layers between runs, avoiding
reinstallation of Octave unless the image definition changes or the cache is
unavailable. The check covers output shape, finite values, and saturation
limits, and verifies that the controller response increases after the load
step.

Generate a standalone HTML report locally after building the MEX module:

```sh
octave --no-gui --quiet octave_pr_report.m
```

The report is written to `artifacts/pr_simulation_report.html` and includes an
inline SVG graph of the simulated load demand, input disturbance, and
controller output. The shared Octave scenario models an illustrative 115 V RMS,
400 Hz aircraft AC bus with a load step from 0.3 to 0.7 p.u. at 0.5 seconds.
It is a teaching example, not a validated aircraft power-system model. GitHub
Actions generates the same report and uploads it as the
`pr-simulation-html-report` artifact, downloadable from the successful workflow
run.

The function signature is:

```text
y = pr_controller_mex(x, fs, f0, bandwidth_rad_s, kp, kr, ymin, ymax)
```

`x` is a real row or column vector. Frequencies and gains are supplied as
real scalar values; `bandwidth_rad_s` is in radians per second. Signal samples
and controller arithmetic use `float` in the shared C core, while the MEX
interface accepts and returns Octave double arrays.

## Publish to GitHub

Create an empty public repository named `sil_mexoct` under `ecneb85` on
GitHub (do not initialize it with a README or other files). Then run this in
PowerShell from the project directory:

```powershell
git init -b main
git add .
git commit -m "Add PR filter Octave simulation"
git remote add origin https://github.com/ecneb85/sil_mexoct.git
git push -u origin main
```

The push starts the simulation workflow. Its result appears in the repository's
**Actions** tab.

## Embedded C

Call `pr_controller_init` once before the control loop, then call
`pr_controller_step` for each sample. A nonzero return value indicates an
invalid parameter or numeric error. `pr_controller_reset` clears the filter
history without changing its configuration.
