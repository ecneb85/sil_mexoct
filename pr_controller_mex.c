#include "mex.h"

#include "pr_controller.h"

#include <float.h>

static float scalar_argument(const mxArray *value, const char *name)
{
    double scalar;

    if (!mxIsDouble(value) ||
        mxIsComplex(value) ||
        mxGetNumberOfElements(value) != 1)
    {
        mexErrMsgIdAndTxt(
            "pr_controller:scalar",
            "%s must be a real double scalar.",
            name);
    }

    scalar = mxGetScalar(value);
    if (scalar != scalar || scalar > FLT_MAX || scalar < -FLT_MAX)
    {
        mexErrMsgIdAndTxt(
            "pr_controller:scalar",
            "%s must fit in a finite float.",
            name);
    }

    return (float)scalar;
}

void mexFunction(
    int output_count,
    mxArray *outputs[],
    int input_count,
    const mxArray *inputs[])
{
    const mwSize *dimensions;
    mwSize dimension_count;
    mwSize sample_count;
    mwSize index;
    const double *signal;
    double *result;
    float sample_output;
    PRController controller;

    if (input_count != 8 || output_count != 1)
    {
        mexErrMsgIdAndTxt(
            "pr_controller:usage",
            "Usage: y = pr_controller_mex(x, fs, f0, bandwidth_rad_s, kp, kr, ymin, ymax)");
    }

    if (!mxIsDouble(inputs[0]) ||
        mxIsComplex(inputs[0]) ||
        mxGetNumberOfDimensions(inputs[0]) > 2)
    {
        mexErrMsgIdAndTxt(
            "pr_controller:signal",
            "The input signal must be a real double vector.");
    }

    dimension_count = mxGetNumberOfDimensions(inputs[0]);
    dimensions = mxGetDimensions(inputs[0]);
    if (dimensions[0] != 1 && dimensions[1] != 1)
    {
        mexErrMsgIdAndTxt(
            "pr_controller:signal",
            "The input signal must be a row or column vector.");
    }

    if (pr_controller_init(
            &controller,
            scalar_argument(inputs[1], "fs"),
            scalar_argument(inputs[2], "f0"),
            scalar_argument(inputs[3], "bandwidth_rad_s"),
            scalar_argument(inputs[4], "kp"),
            scalar_argument(inputs[5], "kr"),
            scalar_argument(inputs[6], "ymin"),
            scalar_argument(inputs[7], "ymax")) != 0)
    {
        mexErrMsgIdAndTxt(
            "pr_controller:parameters",
            "Invalid controller parameters.");
    }

    sample_count = mxGetNumberOfElements(inputs[0]);
    outputs[0] = mxCreateNumericArray(
        dimension_count,
        dimensions,
        mxDOUBLE_CLASS,
        mxREAL);
    signal = mxGetPr(inputs[0]);
    result = mxGetPr(outputs[0]);

    for (index = 0; index < sample_count; ++index)
    {
        if (signal[index] != signal[index] ||
            signal[index] > FLT_MAX ||
            signal[index] < -FLT_MAX)
        {
            mxDestroyArray(outputs[0]);
            mexErrMsgIdAndTxt(
                "pr_controller:sample",
                "Every signal sample must fit in a finite float.");
        }

        if (pr_controller_step(
                &controller,
                (float)signal[index],
                &sample_output) != 0)
        {
            mxDestroyArray(outputs[0]);
            mexErrMsgIdAndTxt(
                "pr_controller:sample",
                "The signal contains a non-finite value or caused numeric overflow.");
        }

        result[index] = (double)sample_output;
    }
}
