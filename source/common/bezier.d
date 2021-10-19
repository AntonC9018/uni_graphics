module common.bezier;

import arsd.simpledisplay;
import common.util;

v2[] getCurvePoints(v2[] controls, float detail)
    in (detail <= 1 && detail >= 0)
{
    v2[] renderingPoints;
    v2[] controlPoints;

    import std.range : iota;

    foreach (i; iota(1, controls.length - 1, 2))
    {
        controlPoints ~= (controls[i - 1] + controls[i]) / 2;
        controlPoints ~= controls[i];
        controlPoints ~= controls[i + 1];

        if (i + 2 < controls.length - 1)
            controlPoints ~= (controls[i + 1] + controls[i + 2]) / 2;
    }

    foreach (i; iota(0, controlPoints.length - 2, 4)) 
    {
        if (i + 3 > controlPoints.length - 1)
        {
            for (double j = 0; j < 1; j += detail)
                renderingPoints ~= getBezierPoint(controlPoints[i .. i + 3][0..3], j);
        }
        else
        {
            for (double j = 0; j < 1; j += detail)
                renderingPoints ~= getBezierPoint(controlPoints[i .. i + 4][0..4], j);
        }
    }

    return renderingPoints;
}

v2 getBezierPoint(in v2[4] points, float t)
{
    auto t_1 = (1 - t);

    return points[0] * t_1^^3
        + points[1] * 3 * t_1^^2 * t
        + points[2] * 3 * t_1 * t^^2
        + points[3] * t^^3;
}

v2 getBezierPoint(in v2[3] points, float t)
{
    auto t_1 = (1 - t);

    return points[0] *  t_1^^2
        + points[1] * 2 * t_1 * t
        + points[2] * t^^2;
}
