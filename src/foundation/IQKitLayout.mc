// F-03 | IQKitLayout
// Interface: IQKit Foundation v1
// Author: Jose Alonso Solis Lemus
// Spec: docs/spec.md#f-03
//
// Screen radius computation, safe-area insets, radial grid helper.
// Depends on IQKitGeometry for coordinate conversion.

using Toybox.Graphics;
using Toybox.Math;
using Toybox.Lang;

module IQKitLayout {

    // Compute the base layout unit from the device context.
    // For round screens: floor of dc width / 2.
    function screenRadius(dc as Graphics.Dc) as Number {
        return (dc.getWidth() / 2).toNumber();
    }

    // Compute the screen centre point.
    // Returns: [cx, cy] as a 2-element Number array.
    function screenCentre(dc as Graphics.Dc) as Array<Number> {
        return [dc.getWidth() / 2, dc.getHeight() / 2];
    }

    // Compute the bezel margin in pixels.
    // Default 5% of screen radius.
    function safeAreaInset(radius as Number) as Number {
        var inset = (radius * 0.05).toNumber();
        if (inset < 1) {
            inset = 1;
        }
        return inset;
    }

    // Place an element at a polar coordinate.
    // Convenience wrapper over IQKitGeometry.polarToCartesian.
    function radialPosition(cx as Number, cy as Number, radius as Number, angleDeg as Float) as Array<Number> {
        return IQKitGeometry.polarToCartesian(cx, cy, radius, angleDeg);
    }
}
