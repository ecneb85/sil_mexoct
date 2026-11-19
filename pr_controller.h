#ifndef PR_CONTROLLER_H
#define PR_CONTROLLER_H

typedef struct
{
    float kp;
    float b0;
    float b1;
    float b2;
    float a1;
    float a2;
    float x1;
    float x2;
    float y1;
    float y2;
    float output_min;
    float output_max;
} PRController;

int pr_controller_init(
    PRController *controller,
    float sample_rate_hz,
    float resonant_hz,
    float bandwidth_rad_s,
    float kp,
    float kr,
    float output_min,
    float output_max);

void pr_controller_reset(PRController *controller);

int pr_controller_step(
    PRController *controller,
    float input,
    float *output);

#endif
