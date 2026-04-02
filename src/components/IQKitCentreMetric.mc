// D-03 | IQKitCentreMetric
// Interface: IQKit Component Interface v1
// Heap delta (FR970 baseline): +0.3 KB
// Spec: docs/spec.md#d-03
//
// Large primary value + unit label, vertically centred on screen.
// Display-only component with AOD variant.

using Toybox.Graphics;
using Toybox.Lang;

class IQKitCentreMetric {
    var _cx as Lang.Number;
    var _cy as Lang.Number;
    var _valueFontSize as Lang.Number;
    var _unitFontSize as Lang.Number;
    var _valueOffsetY as Lang.Number;
    var _unitOffsetY as Lang.Number;
    var _primaryColor as Lang.Number;
    var _secondaryColor as Lang.Number;
    var _dimColor as Lang.Number;
    var _background as Lang.Number;
    var _valueText as Lang.String;
    var _unitText as Lang.String;

    function initialize() {
        _cx = 0;
        _cy = 0;
        _valueFontSize = 0;
        _unitFontSize = 0;
        _valueOffsetY = 0;
        _unitOffsetY = 0;
        _primaryColor = 0xFFFFFF;
        _secondaryColor = 0xB4B4B4;
        _dimColor = 0x3C3C3C;
        _background = 0x000000;
        _valueText = "--";
        _unitText = "";
    }

    function initializeComponent(dc as Graphics.Dc, theme as IQKitThemeTokens) as Void {
        var r = IQKitLayout.screenRadius(dc);
        var centre = IQKitLayout.screenCentre(dc);
        _cx = centre[0];
        _cy = centre[1];

        _valueFontSize = (r * theme.fontSizeLarge * 2.0).toNumber();
        if (_valueFontSize < 12) { _valueFontSize = 12; }
        _unitFontSize = (r * theme.fontSizeMedium).toNumber();
        if (_unitFontSize < 10) { _unitFontSize = 10; }

        _valueOffsetY = -(r * 0.06).toNumber();
        _unitOffsetY = (r * 0.14).toNumber();

        _primaryColor = theme.textColor;
        _secondaryColor = theme.secondaryColor;
        _dimColor = theme.dimColor;
        _background = theme.background;
    }

    function update(valueText as Lang.String, unitText as Lang.String) as Void {
        _valueText = valueText;
        _unitText = unitText;
    }

    function draw(dc as Graphics.Dc) as Void {
        // Value text (large, primary colour).
        dc.setColor(_primaryColor, _background);
        dc.drawText(
            _cx, _cy + _valueOffsetY,
            Graphics.FONT_LARGE,
            _valueText,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );

        // Unit text (medium, secondary colour).
        dc.setColor(_secondaryColor, _background);
        dc.drawText(
            _cx, _cy + _unitOffsetY,
            Graphics.FONT_SMALL,
            _unitText,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }

    function drawAod(dc as Graphics.Dc) as Void {
        // Same layout, dim colour for both elements.
        dc.setColor(_dimColor, _background);
        dc.drawText(
            _cx, _cy + _valueOffsetY,
            Graphics.FONT_LARGE,
            _valueText,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );

        dc.setColor(_dimColor, _background);
        dc.drawText(
            _cx, _cy + _unitOffsetY,
            Graphics.FONT_SMALL,
            _unitText,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }
}
