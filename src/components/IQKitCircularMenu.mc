// N-01 | IQKitCircularMenu
// Interface: IQKit Component Interface v1
// Heap delta (FR970 baseline): +1.0 KB
// Spec: docs/spec.md#n-01
//
// Radial item layout around screen centre. Up to 8 items at equal angular
// intervals. Button nav cycles focus; touch selects directly.

using Toybox.Graphics;
using Toybox.Lang;

class IQKitCircularMenuItem {
    var label as String;

    function initialize(label as String) {
        self.label = label;
    }
}

class IQKitCircularMenuConfig {
    var itemRadiusFraction as Float;
    var ringRadiusFraction as Float;
    var startAngle as Float;
    var title as String;

    function initialize(options as {
        :itemRadiusFraction as Float,
        :ringRadiusFraction as Float,
        :startAngle as Float,
        :title as String
    }) {
        itemRadiusFraction = options.hasKey(:itemRadiusFraction) ? options[:itemRadiusFraction] : 0.12f;
        ringRadiusFraction = options.hasKey(:ringRadiusFraction) ? options[:ringRadiusFraction] : 0.52f;
        startAngle         = options.hasKey(:startAngle)         ? options[:startAngle]         : 270.0f;
        title              = options.hasKey(:title)              ? options[:title]              : "";
    }
}

class IQKitCircularMenu {
    hidden const _MAX_ITEMS = 8;

    var _cx as Number;
    var _cy as Number;
    var _itemX as Array<Number>;
    var _itemY as Array<Number>;
    var _labels as Array<String>;
    var _itemCount as Number;
    var _itemRadius as Number;
    var _centreRadius as Number;
    var _title as String;
    var _focusIndex as Number;
    var _selectedIndex as Number;
    var _accent as Number;
    var _textColor as Number;
    var _secondaryColor as Number;
    var _dimColor as Number;
    var _background as Number;

    function initialize() {
        _cx = 0;
        _cy = 0;
        _itemX = new Array<Number>[_MAX_ITEMS];
        _itemY = new Array<Number>[_MAX_ITEMS];
        _labels = new Array<String>[_MAX_ITEMS];
        for (var i = 0; i < _MAX_ITEMS; i++) {
            _itemX[i] = 0;
            _itemY[i] = 0;
            _labels[i] = "";
        }
        _itemCount = 0;
        _itemRadius = 0;
        _centreRadius = 0;
        _title = "";
        _focusIndex = 0;
        _selectedIndex = -1;
        _accent = 0x00C850;
        _textColor = 0xFFFFFF;
        _secondaryColor = 0xB4B4B4;
        _dimColor = 0x3C3C3C;
        _background = 0x000000;
    }

    function initializeComponent(
        dc as Graphics.Dc,
        theme as IQKitThemeTokens,
        config as IQKitCircularMenuConfig,
        items as Array<IQKitCircularMenuItem>
    ) as Void {
        var r = IQKitLayout.screenRadius(dc);
        var centre = IQKitLayout.screenCentre(dc);
        _cx = centre[0];
        _cy = centre[1];
        _itemRadius = (r * config.itemRadiusFraction).toNumber();
        _centreRadius = (r * 0.18).toNumber();
        _title = config.title;

        var count = items.size();
        if (count > _MAX_ITEMS) { count = _MAX_ITEMS; }
        _itemCount = count;

        if (count > 0) {
            var angleStep = 360.0 / count;
            var ringR = (r * config.ringRadiusFraction).toNumber();
            for (var i = 0; i < count; i++) {
                var angle = config.startAngle + i * angleStep;
                var pos = IQKitLayout.radialPosition(_cx, _cy, ringR, angle);
                _itemX[i] = pos[0];
                _itemY[i] = pos[1];
                _labels[i] = items[i].label;
            }
        }

        _accent = theme.accent;
        _textColor = theme.textColor;
        _secondaryColor = theme.secondaryColor;
        _dimColor = theme.dimColor;
        _background = theme.background;
        _focusIndex = 0;
        _selectedIndex = -1;
    }

    function update(items as Array<IQKitCircularMenuItem>) as Void {
        var count = items.size();
        if (count > _itemCount) { count = _itemCount; }
        for (var i = 0; i < count; i++) {
            _labels[i] = items[i].label;
        }
    }

    function draw(dc as Graphics.Dc) as Void {
        // Centre circle with title.
        dc.setColor(_dimColor, _background);
        dc.fillCircle(_cx, _cy, _centreRadius);
        if (!_title.equals("")) {
            dc.setColor(_textColor, Graphics.COLOR_TRANSPARENT);
            dc.drawText(
                _cx, _cy,
                Graphics.FONT_XTINY,
                _title,
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
            );
        }

        // Item circles.
        for (var i = 0; i < _itemCount; i++) {
            var focused = (i == _focusIndex);
            var ix = _itemX[i];
            var iy = _itemY[i];

            // Background fill.
            dc.setColor(_background, _background);
            dc.fillCircle(ix, iy, _itemRadius);

            // Ring.
            var pen = focused ? 3 : 2;
            dc.setPenWidth(pen);
            dc.setColor(focused ? _accent : _secondaryColor, _background);
            dc.drawCircle(ix, iy, _itemRadius);

            // Label.
            dc.setColor(focused ? _textColor : _secondaryColor, Graphics.COLOR_TRANSPARENT);
            dc.drawText(
                ix, iy,
                Graphics.FONT_XTINY,
                _labels[i],
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
            );
        }
    }

    function drawAod(dc as Graphics.Dc) as Void {
        // No AOD for navigation components.
    }

    function onInput(event as IQKitInputEvent) as Void {
        if (_itemCount == 0) {
            return;
        }

        if (event.action == IQKIT_ACTION_DOWN) {
            _focusIndex = (_focusIndex + 1) % _itemCount;
        } else if (event.action == IQKIT_ACTION_UP) {
            _focusIndex = (_focusIndex - 1 + _itemCount) % _itemCount;
        } else if (event.action == IQKIT_ACTION_ENTER) {
            if (event.inputType == IQKIT_INPUT_TAP && event.x != null) {
                var hit = _hitTest(event.x, event.y);
                if (hit >= 0) {
                    _selectedIndex = hit;
                }
                return;
            }
            _selectedIndex = _focusIndex;
        } else if (event.action == IQKIT_ACTION_BACK) {
            _selectedIndex = -1;
        }
    }

    function getSelectedIndex() as Number {
        return _selectedIndex;
    }

    hidden function _hitTest(tapX as Number, tapY as Number) as Number {
        var rSq = _itemRadius * _itemRadius;
        for (var i = 0; i < _itemCount; i++) {
            var dx = tapX - _itemX[i];
            var dy = tapY - _itemY[i];
            if (dx * dx + dy * dy <= rSq) {
                return i;
            }
        }
        return -1;
    }
}
