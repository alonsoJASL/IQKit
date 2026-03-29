// N-05 | IQKitConfirmDialog
// Interface: IQKit Component Interface v1
// Heap delta (FR970 baseline): +0.5 KB
// Spec: docs/spec.md#n-05
//
// Full-screen binary confirm/cancel dialog. Two circular buttons at radial
// positions. Supports both button navigation and touch selection.

using Toybox.Graphics;
using Toybox.Lang;

// Result constants.
const IQKIT_DIALOG_PENDING = -1;
const IQKIT_DIALOG_CONFIRM = 0;
const IQKIT_DIALOG_CANCEL = 1;

class IQKitConfirmDialogConfig {
    var promptText as String;
    var confirmLabel as String;
    var cancelLabel as String;
    var confirmAngle as Float;
    var cancelAngle as Float;
    var buttonRadiusFraction as Float;
    var buttonDistanceFraction as Float;

    function initialize(options as {
        :promptText as String,
        :confirmLabel as String,
        :cancelLabel as String,
        :confirmAngle as Float,
        :cancelAngle as Float,
        :buttonRadiusFraction as Float,
        :buttonDistanceFraction as Float
    }) {
        promptText             = options.hasKey(:promptText)             ? options[:promptText]             : "Confirm?";
        confirmLabel           = options.hasKey(:confirmLabel)           ? options[:confirmLabel]           : "Yes";
        cancelLabel            = options.hasKey(:cancelLabel)            ? options[:cancelLabel]            : "No";
        confirmAngle           = options.hasKey(:confirmAngle)           ? options[:confirmAngle]           : 45.0f;
        cancelAngle            = options.hasKey(:cancelAngle)            ? options[:cancelAngle]            : 135.0f;
        buttonRadiusFraction   = options.hasKey(:buttonRadiusFraction)   ? options[:buttonRadiusFraction]   : 0.18f;
        buttonDistanceFraction = options.hasKey(:buttonDistanceFraction) ? options[:buttonDistanceFraction] : 0.42f;
    }
}

class IQKitConfirmDialog {
    var _cx as Number;
    var _cy as Number;
    var _promptY as Number;
    var _buttonRadius as Number;
    var _confirmX as Number;
    var _confirmY as Number;
    var _cancelX as Number;
    var _cancelY as Number;
    var _promptText as String;
    var _confirmLabel as String;
    var _cancelLabel as String;
    var _focusIndex as Number;
    var _result as Number;
    var _accent as Number;
    var _warning as Number;
    var _textColor as Number;
    var _secondaryColor as Number;
    var _dimColor as Number;
    var _background as Number;

    function initialize() {
        _cx = 0;
        _cy = 0;
        _promptY = 0;
        _buttonRadius = 0;
        _confirmX = 0;
        _confirmY = 0;
        _cancelX = 0;
        _cancelY = 0;
        _promptText = "Confirm?";
        _confirmLabel = "Yes";
        _cancelLabel = "No";
        _focusIndex = 0;
        _result = IQKIT_DIALOG_PENDING;
        _accent = 0x00C850;
        _warning = 0xFF5028;
        _textColor = 0xFFFFFF;
        _secondaryColor = 0xB4B4B4;
        _dimColor = 0x3C3C3C;
        _background = 0x000000;
    }

    function initializeComponent(
        dc as Graphics.Dc,
        theme as IQKitThemeTokens,
        config as IQKitConfirmDialogConfig or Null
    ) as Void {
        if (config == null) {
            config = new IQKitConfirmDialogConfig({});
        }

        var r = IQKitLayout.screenRadius(dc);
        var centre = IQKitLayout.screenCentre(dc);
        _cx = centre[0];
        _cy = centre[1];
        _promptY = _cy - (r * 0.25).toNumber();
        _buttonRadius = (r * config.buttonRadiusFraction).toNumber();

        var dist = (r * config.buttonDistanceFraction).toNumber();
        var confirmPos = IQKitLayout.radialPosition(_cx, _cy, dist, config.confirmAngle);
        _confirmX = confirmPos[0];
        _confirmY = confirmPos[1];

        var cancelPos = IQKitLayout.radialPosition(_cx, _cy, dist, config.cancelAngle);
        _cancelX = cancelPos[0];
        _cancelY = cancelPos[1];

        _promptText = config.promptText;
        _confirmLabel = config.confirmLabel;
        _cancelLabel = config.cancelLabel;

        _accent = theme.accent;
        _warning = theme.warning;
        _textColor = theme.textColor;
        _secondaryColor = theme.secondaryColor;
        _dimColor = theme.dimColor;
        _background = theme.background;

        _focusIndex = 0;
        _result = IQKIT_DIALOG_PENDING;
    }

    function update(promptText as String) as Void {
        _promptText = promptText;
    }

    function draw(dc as Graphics.Dc) as Void {
        // Prompt text.
        dc.setColor(_textColor, _background);
        dc.drawText(
            _cx, _promptY,
            Graphics.FONT_SMALL,
            _promptText,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );

        // Confirm button.
        _drawButton(dc, _confirmX, _confirmY, _confirmLabel,
            _focusIndex == 0 ? _accent : _dimColor, _focusIndex == 0);

        // Cancel button.
        _drawButton(dc, _cancelX, _cancelY, _cancelLabel,
            _focusIndex == 1 ? _warning : _dimColor, _focusIndex == 1);
    }

    function drawAod(dc as Graphics.Dc) as Void {
        // No AOD for navigation components.
    }

    function onInput(event as IQKitInputEvent) as Void {
        if (event.action == IQKIT_ACTION_UP || event.action == IQKIT_ACTION_DOWN) {
            _focusIndex = 1 - _focusIndex;
        } else if (event.action == IQKIT_ACTION_ENTER) {
            if (event.inputType == IQKIT_INPUT_TAP && event.x != null) {
                var hit = _hitTest(event.x, event.y);
                if (hit != null) {
                    _result = hit;
                }
                return;
            }
            _result = _focusIndex == 0 ? IQKIT_DIALOG_CONFIRM : IQKIT_DIALOG_CANCEL;
        } else if (event.action == IQKIT_ACTION_BACK) {
            _result = IQKIT_DIALOG_CANCEL;
        }
    }

    function getResult() as Number {
        return _result;
    }

    hidden function _hitTest(tapX as Number, tapY as Number) as Number or Null {
        var rSq = _buttonRadius * _buttonRadius;
        var dx = tapX - _confirmX;
        var dy = tapY - _confirmY;
        if (dx * dx + dy * dy <= rSq) {
            return IQKIT_DIALOG_CONFIRM;
        }
        dx = tapX - _cancelX;
        dy = tapY - _cancelY;
        if (dx * dx + dy * dy <= rSq) {
            return IQKIT_DIALOG_CANCEL;
        }
        return null;
    }

    hidden function _drawButton(
        dc as Graphics.Dc,
        bx as Number,
        by as Number,
        label as String,
        ringColor as Number,
        focused as Boolean
    ) as Void {
        // Filled background.
        dc.setColor(_background, _background);
        dc.fillCircle(bx, by, _buttonRadius);

        // Ring.
        var pen = focused ? 3 : 2;
        dc.setPenWidth(pen);
        dc.setColor(ringColor, _background);
        dc.drawCircle(bx, by, _buttonRadius);

        // Label.
        dc.setColor(focused ? _textColor : _secondaryColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            bx, by,
            Graphics.FONT_XTINY,
            label,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }
}
