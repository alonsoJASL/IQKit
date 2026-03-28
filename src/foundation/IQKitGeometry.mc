// F-01 | IQKitGeometry
// Interface: IQKit Foundation v1
// Author: Jose Alonso Solis Lemus
// Spec: docs/spec.md#f-01
//
// Polar-to-cartesian conversion, arc segment math, polygon approximation.
// All functions are pure. No side effects. No Garmin API calls.
// The Python harness implementation in harness/geometry.py must produce
// identical output for the same inputs.

using Toybox.Math;
using Toybox.Lang;

module IQKitGeometry {

    // Convert polar coordinates to cartesian pixel coordinates.
    //
    // cx, cy: centre in pixels.
    // r: radius in pixels.
    // angleDeg: angle in degrees. 0 = right (3 o'clock), 90 = down,
    //           270 = up (12 o'clock on a watch face).
    //
    // Returns: [x, y] as a 2-element Number array.
    function polarToCartesian(cx as Number, cy as Number, r as Number, angleDeg as Float) as Array<Number> {
        var angleRad = Math.toRadians(angleDeg);
        var x = cx + (r * Math.cos(angleRad)).toNumber();
        var y = cy + (r * Math.sin(angleRad)).toNumber();
        return [x, y];
    }

    // Generate a sequence of cartesian points along an arc.
    //
    // Points are evenly spaced from startDeg to endDeg (inclusive).
    // numSegments: number of line segments (numSegments + 1 points).
    //
    // Returns: Array of [x, y] pairs.
    function arcPoints(
        cx as Number,
        cy as Number,
        r as Number,
        startDeg as Float,
        endDeg as Float,
        numSegments as Number
    ) as Array< Array<Number> > {
        if (numSegments < 1) {
            numSegments = 1;
        }
        var step = (endDeg - startDeg) / numSegments;
        var points = new Array< Array<Number> >[numSegments + 1];
        for (var i = 0; i <= numSegments; i++) {
            points[i] = polarToCartesian(cx, cy, r, startDeg + i * step);
        }
        return points;
    }

    // Generate a closed polygon approximating an arc band (annular sector).
    //
    // Traces outer arc start->end, then inner arc end->start.
    // Suitable for Dc.fillPolygon().
    //
    // Returns: Array of [x, y] pairs forming a closed polygon.
    function polygonFromArc(
        cx as Number,
        cy as Number,
        rInner as Number,
        rOuter as Number,
        startDeg as Float,
        endDeg as Float,
        numSegments as Number
    ) as Array< Array<Number> > {
        var outer = arcPoints(cx, cy, rOuter, startDeg, endDeg, numSegments);
        var inner = arcPoints(cx, cy, rInner, endDeg, startDeg, numSegments);
        var total = outer.size() + inner.size();
        var polygon = new Array< Array<Number> >[total];
        for (var i = 0; i < outer.size(); i++) {
            polygon[i] = outer[i];
        }
        for (var i = 0; i < inner.size(); i++) {
            polygon[outer.size() + i] = inner[i];
        }
        return polygon;
    }
}
