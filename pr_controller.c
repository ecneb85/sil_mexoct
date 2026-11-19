#include "pr_controller.h"

#include <float.h>

#define PR_PI 3.14159265358979323846f

static int pr_is_finite(float value)
{
    return (value == value) &&
           (value <= FLT_MAX) &&
           (value >= -FLT_MAX);
}

int pr_controller_init(
    PRController *controller,
    float sample_rate_hz,
    float resonant_hz,
    float bandwidth_rad_s,
    float kp,
    float kr,
    float output_min,
    float output_max)
{
    float two_fs;
    float omega;
    float damping;
    float omega_squared;
    float denominator;
    float numerator;
    PRController initialized;

    if (controller == 0 ||
        !pr_is_finite(sample_rate_hz) ||
        !pr_is_finite(resonant_hz) ||
        !pr_is_finite(bandwidth_rad_s) ||
        !pr_is_finite(kp) ||
        !pr_is_finite(kr) ||
        !pr_is_finite(output_min) ||
        !pr_is_finite(output_max) ||
        sample_rate_hz <= 0.0f ||
        resonant_hz <= 0.0f ||
        resonant_hz >= sample_rate_hz * 0.5f ||
        bandwidth_rad_s <= 0.0f ||
        output_min >= output_max)
    {
        return -1;
    }

    /*
     * Tustin-discretized resonant branch:
     * Kr * (2 * bandwidth * s) /
     * (s^2 + 2 * bandwidth * s + omega^2).
     */
    two_fs = 2.0f * sample_rate_hz;
    omega = 2.0f * PR_PI * resonant_hz;
    damping = 2.0f * bandwidth_rad_s;
    omega_squared = omega * omega;
    denominator = two_fs * two_fs +
                  damping * two_fs +
                  omega_squared;

    if (!pr_is_finite(denominator) || denominator <= 0.0f)
    {
        return -1;
    }

    numerator = kr * damping * two_fs;
    initialized.kp = kp;
    initialized.b0 = numerator / denominator;
    initialized.b1 = 0.0f;
    initialized.b2 = -initialized.b0;
    initialized.a1 = (-2.0f * two_fs * two_fs +
                      2.0f * omega_squared) / denominator;
    initialized.a2 = (two_fs * two_fs -
                      damping * two_fs +
                      omega_squared) / denominator;
    initialized.x1 = 0.0f;
    initialized.x2 = 0.0f;
    initialized.y1 = 0.0f;
    initialized.y2 = 0.0f;
    initialized.output_min = output_min;
    initialized.output_max = output_max;

    if (!pr_is_finite(initialized.b0) ||
        !pr_is_finite(initialized.a1) ||
        !pr_is_finite(initialized.a2))
    {
        return -1;
    }

    *controller = initialized;
    return 0;
}

void pr_controller_reset(PRController *controller)
{
    if (controller != 0)
    {
        controller->x1 = 0.0f;
        controller->x2 = 0.0f;
        controller->y1 = 0.0f;
        controller->y2 = 0.0f;
    }
}

int pr_controller_step(
    PRController *controller,
    float input,
    float *output)
{
    float resonant_output;
    float result;

    if (controller == 0 || output == 0 || !pr_is_finite(input))
    {
        return -1;
    }

    resonant_output = controller->b0 * input +
                      controller->b1 * controller->x1 +
                      controller->b2 * controller->x2 -
                      controller->a1 * controller->y1 -
                      controller->a2 * controller->y2;
    result = controller->kp * input + resonant_output;

    if (!pr_is_finite(resonant_output) || !pr_is_finite(result))
    {
        return -1;
    }

    controller->x2 = controller->x1;
    controller->x1 = input;
    controller->y2 = controller->y1;
    controller->y1 = resonant_output;

    if (result > controller->output_max)
    {
        result = controller->output_max;
    }
    else if (result < controller->output_min)
    {
        result = controller->output_min;
    }

    *output = result;
    return 0;
}
