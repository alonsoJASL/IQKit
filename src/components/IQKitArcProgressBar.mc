// D-01 | IQKitArcProgressBar
// Interface: IQKit Component Interface v1
// Heap delta (FR970 baseline): +1.2 KB
// Spec: docs/spec.md#d-01
//
// Single-value arc indicator. Renders a background track arc and a fill
// arc proportional to a 0.0-1.0 progress value. Start/end angle
// configurable via IQKitArcProgressBarConfig.

using Toybox.Graphics;
using Toybox.Lang;
using Toybox.Math;

class IQKitArcProgressBarConfig {
    var startAngle as Lang.Float;
    var endAngle as Lang.Float;
    var radiusFraction as Lang.Float;
    var thicknessFraction as Lang.Float;
    var trackColor as Lang.Number or Null;
    var fillColor as Lang.Number or Null;

    function initialize(options as {
        :startAngle as Lang.Float,
        :endAngle as Lang.Float,
        :radiusFraction as Lang.Float,
        :thicknessFraction as Lang.Float,
        :trackColor as Lang.Number,
        :fillColor as Lang.Number
    }) {
        startAngle        = options.hasKey(:startAngle)        ? options[:startAngle]        : 135.0f;
        endAngle          = options.hasKey(:endAngle)          ? options[:endAngle]          : 405.0f;
        radiusFraction    = options.hasKey(:radiusFraction)    ? options[:radiusFraction]    : 0.70f;
        thicknessFraction = options.hasKey(:thicknessFraction) ? options[:thicknessFraction] : 0.08f;
        trackColor        = options.hasKey(:trackColor)        ? options[:trackColor]        : null;
        fillColor         = options.hasKey(:fillColor)         ? options[:fillColor]         : null;
    }
}

class IQKitArcProgressBar {
    var _cx as Lang.Number;
    var _cy as Lang.Number;
    var _rInner as Lang.Number;
    var _rOuter as Lang.Number;
    var _rMid as Lang.Number;
    var _startAngle as Lang.Float;
    var _endAngle as Lang.Float;
    var _numSegments as Lang.Number;
    var _trackPolygon as Lang.Array< Lang.Array<Lang.Number> >;
    var _fillPolygon as Lang.Array< Lang.Array<Lang.Number> >;
    var _trackColor as Lang.Number;
    var _fillColor as Lang.Number;
    var _dimColor as Lang.Number;
    var _background as Lang.Number;
    var _progress as Lang.Float;
    var _markerX as Lang.Number;
    var _markerY as Lang.Number;

    function initialize() {
        _cx = 0;
        _cy = 0;
        _rInner = 0;
        _rOuter = 0;
        _rMid = 0;
        _startAngle = 135.0f;
        _endAngle = 405.0f;
        _numSegments = 72;
        _trackPolygon = [];
        _fillPolygon = [];
        _trackColor = 0x3C3C3C;
        _fillColor = 0x00C850;
        _dimColor = 0x3C3C3C;
        _background = 0x000000;
        _progress = 0.0f;
        _markerX = 0;
        _markerY = 0;
    }

    function initializeComponent(
        dc as Graphics.Dc,
        theme as IQKitThemeTokens,
        config as IQKitArcProgressBarConfig or Null
    ) as Void {
        if (config == null) {
            config = new IQKitArcProgressBarConfig({});
        }

        var r = IQKitLayout.screenRadius(dc);
        var centre = IQKitLayout.screenCentre(dc);
        _cx = centre[0];
        _cy = centre[1];
        _startAngle = config.startAngle;
        _endAngle = config.endAngle;

        var halfThick = (r * config.thicknessFraction / 2).toNumber();
        var midR = (r * config.radiusFraction).toNumber();
        _rMid = midR;
        _rInner = midR - halfThick;
        _rOuter = midR + halfThick;

        _trackColor = config.trackColor != null ? config.trackColor : theme.dimColor;
        _fillColor = config.fillColor != null ? config.fillColor : theme.accent;
        _dimColor = theme.dimColor;
        _background = theme.background;

        _trackPolygon = IQKitGeometry.polygonFromArc(
            _cx, _cy, _rInner, _rOuter,
            _startAngle, _endAngle, _numSegments
        );
        _fillPolygon = [];

        var pos = IQKitGeometry.polarToCartesian(_cx, _cy, _rMid, _startAngle);
        _markerX = pos[0];
        _markerY = pos[1];
    }

    function update(progress as Lang.Float) as Void {
        if (progress < 0.0) { progress = 0.0; }
        if (progress > 1.0) { progress = 1.0; }
        _progress = progress;

        var sweep = _endAngle - _startAngle;
        var fillEnd = _startAngle + _progress * sweep;

        if (_progress > 0.001) {
            var segCount = (_numSegments * _progress).toNumber();
            if (segCount < 4) { segCount = 4; }
            _fillPolygon = IQKitGeometry.polygonFromArc(
                _cx, _cy, _rInner, _rOuter,
                _startAngle, fillEnd, segCount
            );
        } else {
            _fillPolygon = [];
        }

        var pos = IQKitGeometry.polarToCartesian(_cx, _cy, _rMid, fillEnd);
        _markerX = pos[0];
        _markerY = pos[1];
    }

    function draw(dc as Graphics.Dc) as Void {
        // Track (full background arc).
        dc.setColor(_trackColor, _background);
        dc.fillPolygon(_trackPolygon as Lang.Array<Graphics.Point2D>);

        // Fill (proportional arc).
        if (_fillPolygon.size() >= 3) {
            dc.setColor(_fillColor, _background);
            dc.fillPolygon(_fillPolygon as Lang.Array<Graphics.Point2D>);
        }
    }

    function drawAod(dc as Graphics.Dc) as Void {
        // Thin arc outline.
        var pen = (IQKitLayout.screenRadius(dc) * 0.005).toNumber();
        if (pen < 1) { pen = 1; }
        dc.setPenWidth(pen);
        dc.setColor(_dimColor, _background);

        var arcPts = IQKitGeometry.arcPoints(
            _cx, _cy, _rMid, _startAngle, _endAngle, _numSegments
        );
        for (var i = 0; i < arcPts.size() - 1; i++) {
            dc.drawLine(arcPts[i][0], arcPts[i][1], arcPts[i + 1][0], arcPts[i + 1][1]);
        }

        // Small dot at fill position.
        var dotR = (IQKitLayout.screenRadius(dc) * 0.015).toNumber();
        if (dotR < 2) { dotR = 2; }
        dc.fillCircle(_markerX, _markerY, dotR);
    }
}
