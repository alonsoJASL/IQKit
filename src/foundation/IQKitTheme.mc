// F-02 | IQKitTheme
// Interface: IQKit Foundation v1
// Author: Jose Alonso Solis Lemus
// Spec: docs/spec.md#f-02
//
// Centralised colour palette, font size tokens, stroke weight tokens.
// This is NOT a singleton or global. Callers construct an instance and
// inject it into components at initialize() time.
// See DESIGN.md Section 7 for the rationale.

using Toybox.Graphics;
using Toybox.Lang;

class IQKitThemeTokens {
    // Colours as Graphics colour constants (0xRRGGBB).
    var primaryColor as Number;
    var secondaryColor as Number;
    var background as Number;
    var textColor as Number;
    var accent as Number;
    var warning as Number;
    var dimColor as Number;  // AOD low-brightness colour

    // Font sizes as fractions of screenRadius.
    // Caller resolves to pixel integers at initialize() time.
    var fontSizeLarge as Float;
    var fontSizeMedium as Float;
    var fontSizeSmall as Float;

    // Stroke weights as fractions of screenRadius.
    var strokeWeightThick as Float;
    var strokeWeightThin as Float;

    function initialize(options as {
        :primaryColor as Number,
        :secondaryColor as Number,
        :background as Number,
        :textColor as Number,
        :accent as Number,
        :warning as Number,
        :dimColor as Number,
        :fontSizeLarge as Float,
        :fontSizeMedium as Float,
        :fontSizeSmall as Float,
        :strokeWeightThick as Float,
        :strokeWeightThin as Float
    }) {
        primaryColor   = options.hasKey(:primaryColor)   ? options[:primaryColor]   : 0xFFFFFF;
        secondaryColor = options.hasKey(:secondaryColor) ? options[:secondaryColor] : 0xB4B4B4;
        background     = options.hasKey(:background)     ? options[:background]     : 0x000000;
        textColor      = options.hasKey(:textColor)      ? options[:textColor]      : 0xFFFFFF;
        accent         = options.hasKey(:accent)          ? options[:accent]          : 0x00C850;
        warning        = options.hasKey(:warning)         ? options[:warning]         : 0xFF5028;
        dimColor       = options.hasKey(:dimColor)        ? options[:dimColor]        : 0x3C3C3C;

        fontSizeLarge  = options.hasKey(:fontSizeLarge)  ? options[:fontSizeLarge]  : 0.14f;
        fontSizeMedium = options.hasKey(:fontSizeMedium) ? options[:fontSizeMedium] : 0.09f;
        fontSizeSmall  = options.hasKey(:fontSizeSmall)  ? options[:fontSizeSmall]  : 0.06f;

        strokeWeightThick = options.hasKey(:strokeWeightThick) ? options[:strokeWeightThick] : 0.03f;
        strokeWeightThin  = options.hasKey(:strokeWeightThin)  ? options[:strokeWeightThin]  : 0.01f;
    }
}
