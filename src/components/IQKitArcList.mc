// N-02 | IQKitArcList
// Interface: IQKit Component Interface v1
// Heap delta (FR970 baseline): +1.5 KB
// Spec: docs/spec.md#n-02
//
// Curved vertical list following the screen's interior arc. Item widths
// are constrained by chord length at each y-position, eliminating
// rectangular clipping on round screens. Supports scrolling.

using Toybox.Graphics;
using Toybox.Lang;
using Toybox.Math;

class IQKitArcListItem {
    var primaryText as Lang.String;
    var secondaryText as Lang.String;

    function initialize(primaryText as Lang.String, secondaryText as Lang.String) {
        self.primaryText = primaryText;
        self.secondaryText = secondaryText;
    }
}

class IQKitArcListConfig {
    var visibleItems as Lang.Number;
    var itemHeightFraction as Lang.Float;
    var insetFraction as Lang.Float;
    var showScrollbar as Lang.Boolean;

    function initialize(options as {
        :visibleItems as Lang.Number,
        :itemHeightFraction as Lang.Float,
        :insetFraction as Lang.Float,
        :showScrollbar as Lang.Boolean
    }) {
        visibleItems      = options.hasKey(:visibleItems)      ? options[:visibleItems]      : 5;
        itemHeightFraction = options.hasKey(:itemHeightFraction) ? options[:itemHeightFraction] : 0.12f;
        insetFraction     = options.hasKey(:insetFraction)     ? options[:insetFraction]     : 0.08f;
        showScrollbar     = options.hasKey(:showScrollbar)     ? options[:showScrollbar]     : true;
    }
}

class IQKitArcList {
    hidden const _MAX_VISIBLE = 7;

    var _cx as Lang.Number;
    var _cy as Lang.Number;
    var _radius as Lang.Number;
    var _itemHeight as Lang.Number;
    var _visibleCount as Lang.Number;
    var _inset as Lang.Number;
    var _slotY as Lang.Array<Lang.Number>;
    var _slotXLeft as Lang.Array<Lang.Number>;
    var _slotXRight as Lang.Array<Lang.Number>;
    var _slotWidth as Lang.Array<Lang.Number>;
    var _items as Lang.Array<IQKitArcListItem>;
    var _itemCount as Lang.Number;
    var _scrollOffset as Lang.Number;
    var _focusIndex as Lang.Number;
    var _selectedIndex as Lang.Number;
    var _showScrollbar as Lang.Boolean;
    var _accent as Lang.Number;
    var _textColor as Lang.Number;
    var _secondaryColor as Lang.Number;
    var _dimColor as Lang.Number;
    var _background as Lang.Number;

    function initialize() {
        _cx = 0;
        _cy = 0;
        _radius = 0;
        _itemHeight = 0;
        _visibleCount = 0;
        _inset = 0;
        _slotY = new Lang.Array<Lang.Number>[_MAX_VISIBLE];
        _slotXLeft = new Lang.Array<Lang.Number>[_MAX_VISIBLE];
        _slotXRight = new Lang.Array<Lang.Number>[_MAX_VISIBLE];
        _slotWidth = new Lang.Array<Lang.Number>[_MAX_VISIBLE];
        for (var i = 0; i < _MAX_VISIBLE; i++) {
            _slotY[i] = 0;
            _slotXLeft[i] = 0;
            _slotXRight[i] = 0;
            _slotWidth[i] = 0;
        }
        _items = [];
        _itemCount = 0;
        _scrollOffset = 0;
        _focusIndex = 0;
        _selectedIndex = -1;
        _showScrollbar = true;
        _accent = 0x00C850;
        _textColor = 0xFFFFFF;
        _secondaryColor = 0xB4B4B4;
        _dimColor = 0x3C3C3C;
        _background = 0x000000;
    }

    function initializeComponent(
        dc as Graphics.Dc,
        theme as IQKitThemeTokens,
        config as IQKitArcListConfig or Null
    ) as Void {
        if (config == null) {
            config = new IQKitArcListConfig({});
        }

        var r = IQKitLayout.screenRadius(dc);
        var centre = IQKitLayout.screenCentre(dc);
        _cx = centre[0];
        _cy = centre[1];
        _radius = r;

        _itemHeight = (r * config.itemHeightFraction).toNumber();
        if (_itemHeight < 20) { _itemHeight = 20; }
        _visibleCount = config.visibleItems;
        if (_visibleCount > _MAX_VISIBLE) { _visibleCount = _MAX_VISIBLE; }
        _inset = (r * config.insetFraction).toNumber();
        if (_inset < 2) { _inset = 2; }
        _showScrollbar = config.showScrollbar;

        // Compute slot geometry using chord-width at each y-position.
        var totalH = _visibleCount * _itemHeight;
        var startY = _cy - totalH / 2;

        for (var i = 0; i < _visibleCount; i++) {
            var slotMidY = startY + i * _itemHeight + _itemHeight / 2;
            _slotY[i] = startY + i * _itemHeight;

            var dy = slotMidY - _cy;
            var dySq = dy * dy;
            var rSq = r * r;

            var halfChord = 10;
            if (dySq < rSq) {
                halfChord = Math.sqrt(rSq - dySq).toNumber() - _inset;
                if (halfChord < 10) { halfChord = 10; }
            }

            _slotXLeft[i] = _cx - halfChord;
            _slotXRight[i] = _cx + halfChord;
            _slotWidth[i] = halfChord * 2;
        }

        _accent = theme.accent;
        _textColor = theme.textColor;
        _secondaryColor = theme.secondaryColor;
        _dimColor = theme.dimColor;
        _background = theme.background;
        _scrollOffset = 0;
        _focusIndex = 0;
        _selectedIndex = -1;
    }

    function update(items as Lang.Array<IQKitArcListItem>) as Void {
        _items = items;
        _itemCount = items.size();
        _scrollOffset = 0;
        _focusIndex = 0;
        _selectedIndex = -1;
    }

    function draw(dc as Graphics.Dc) as Void {
        for (var slot = 0; slot < _visibleCount; slot++) {
            var itemIdx = _scrollOffset + slot;
            if (itemIdx >= _itemCount) {
                break;
            }

            var item = _items[itemIdx];
            var focused = (itemIdx == _focusIndex);
            var xLeft = _slotXLeft[slot];
            var xRight = _slotXRight[slot];
            var yTop = _slotY[slot];
            var textX = _cx;

            // Focused item background highlight.
            if (focused) {
                dc.setColor(_dimColor, _background);
                dc.fillRectangle(xLeft, yTop, _slotWidth[slot], _itemHeight);
            }

            // Primary text.
            var textY = yTop + _itemHeight / 2;
            if (!item.secondaryText.equals("")) {
                textY = yTop + (_itemHeight * 35 / 100);
            }
            dc.setColor(focused ? _textColor : _secondaryColor, Graphics.COLOR_TRANSPARENT);
            dc.drawText(
                textX, textY,
                Graphics.FONT_XTINY,
                item.primaryText,
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
            );

            // Secondary text.
            if (!item.secondaryText.equals("")) {
                var secY = yTop + (_itemHeight * 70 / 100);
                dc.setColor(_secondaryColor, Graphics.COLOR_TRANSPARENT);
                dc.drawText(
                    textX, secY,
                    Graphics.FONT_XTINY,
                    item.secondaryText,
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
                );
            }
        }

        // Scrollbar.
        if (_showScrollbar && _itemCount > _visibleCount) {
            _drawScrollbar(dc);
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
            if (_focusIndex < _itemCount - 1) {
                _focusIndex += 1;
                if (_focusIndex >= _scrollOffset + _visibleCount) {
                    _scrollOffset += 1;
                }
            }
        } else if (event.action == IQKIT_ACTION_UP) {
            if (_focusIndex > 0) {
                _focusIndex -= 1;
                if (_focusIndex < _scrollOffset) {
                    _scrollOffset -= 1;
                }
            }
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

    function getSelectedIndex() as Lang.Number {
        return _selectedIndex;
    }

    hidden function _hitTest(tapX as Lang.Number, tapY as Lang.Number) as Lang.Number {
        for (var slot = 0; slot < _visibleCount; slot++) {
            var itemIdx = _scrollOffset + slot;
            if (itemIdx >= _itemCount) {
                break;
            }
            var yTop = _slotY[slot];
            if (tapY >= yTop && tapY < yTop + _itemHeight) {
                if (tapX >= _slotXLeft[slot] && tapX <= _slotXRight[slot]) {
                    return itemIdx;
                }
            }
        }
        return -1;
    }

    hidden function _drawScrollbar(dc as Graphics.Dc) as Void {
        // Thin arc scrollbar on the right side.
        var trackStart = 340.0f;
        var trackEnd = 380.0f;
        var trackR = _radius - _inset / 2;

        // Track arc (dim).
        var pen = (_radius * 0.005).toNumber();
        if (pen < 1) { pen = 1; }
        dc.setPenWidth(pen);
        dc.setColor(_dimColor, _background);
        var trackPts = IQKitGeometry.arcPoints(_cx, _cy, trackR, trackStart, trackEnd, 20);
        for (var i = 0; i < trackPts.size() - 1; i++) {
            dc.drawLine(trackPts[i][0], trackPts[i][1], trackPts[i + 1][0], trackPts[i + 1][1]);
        }

        // Thumb arc (accent).
        var sweep = trackEnd - trackStart;
        var thumbFraction = _visibleCount.toFloat() / _itemCount;
        var thumbOffset = _scrollOffset.toFloat() / _itemCount;
        var thumbStart = trackStart + thumbOffset * sweep;
        var thumbEnd = thumbStart + thumbFraction * sweep;

        var thumbPen = (_radius * 0.012).toNumber();
        if (thumbPen < 2) { thumbPen = 2; }
        dc.setPenWidth(thumbPen);
        dc.setColor(_accent, _background);
        var thumbPts = IQKitGeometry.arcPoints(_cx, _cy, trackR, thumbStart, thumbEnd, 10);
        for (var i = 0; i < thumbPts.size() - 1; i++) {
            dc.drawLine(thumbPts[i][0], thumbPts[i][1], thumbPts[i + 1][0], thumbPts[i + 1][1]);
        }
    }
}
