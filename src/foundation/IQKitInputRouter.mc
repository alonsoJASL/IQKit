// F-04 | IQKitInputRouter
// Interface: IQKit Foundation v1
// Author: Jose Alonso Solis Lemus
// Spec: docs/spec.md#f-04
//
// Unified tap/swipe/key event dispatcher. Normalises Toybox button and
// touch events into a common IQKitInputEvent that components consume.
// Focus management: tracks which component has focus and routes events to it.

using Toybox.Lang;
using Toybox.WatchUi;

// Input type constants.
enum IQKitInputType {
    IQKIT_INPUT_KEY = 0,
    IQKIT_INPUT_TAP = 1,
}

// Normalised action constants matching the dual-input contract.
enum IQKitInputAction {
    IQKIT_ACTION_UP    = 0,
    IQKIT_ACTION_DOWN  = 1,
    IQKIT_ACTION_ENTER = 2,
    IQKIT_ACTION_BACK  = 3,
}

// Normalised input event consumed by components.
class IQKitInputEvent {
    var inputType as IQKitInputType;
    var action as IQKitInputAction;
    var x as Number or Null;  // Pixel coordinate, TAP events only.
    var y as Number or Null;

    function initialize(
        inputType as IQKitInputType,
        action as IQKitInputAction,
        x as Number or Null,
        y as Number or Null
    ) {
        self.inputType = inputType;
        self.action = action;
        self.x = x;
        self.y = y;
    }
}

// Receives Toybox events, normalises them, and dispatches to the focused
// component. Components register via addTarget(). The router tracks focus
// and routes events.
class IQKitInputRouter {
    var _targets as Array;
    var _focusIndex as Number;

    function initialize() {
        _targets = [];
        _focusIndex = -1;
    }

    // Register a component as an input target.
    // Target must implement onInput(event as IQKitInputEvent).
    function addTarget(target) as Void {
        _targets.add(target);
        if (_focusIndex < 0) {
            _focusIndex = 0;
        }
    }

    // Move focus by delta positions (wraps around).
    function moveFocus(delta as Number) as Void {
        var count = _targets.size();
        if (count == 0) {
            return;
        }
        _focusIndex = (_focusIndex + delta) % count;
        if (_focusIndex < 0) {
            _focusIndex = _focusIndex + count;
        }
    }

    // Normalise a Toybox key event and dispatch to the focused target.
    // Returns the normalised event, or null if the key is not mapped.
    function onKey(keyEvent as WatchUi.KeyEvent) as IQKitInputEvent or Null {
        var key = keyEvent.getKey();
        var action = null;

        if (key == WatchUi.KEY_UP) {
            action = IQKIT_ACTION_UP;
        } else if (key == WatchUi.KEY_DOWN) {
            action = IQKIT_ACTION_DOWN;
        } else if (key == WatchUi.KEY_ENTER) {
            action = IQKIT_ACTION_ENTER;
        } else if (key == WatchUi.KEY_ESC) {
            action = IQKIT_ACTION_BACK;
        }

        if (action == null) {
            return null;
        }

        var event = new IQKitInputEvent(IQKIT_INPUT_KEY, action, null, null);
        _dispatch(event);
        return event;
    }

    // Normalise a Toybox tap event and dispatch to the focused target.
    function onTap(clickEvent as WatchUi.ClickEvent) as IQKitInputEvent {
        var coords = clickEvent.getCoordinates();
        var event = new IQKitInputEvent(
            IQKIT_INPUT_TAP,
            IQKIT_ACTION_ENTER,
            coords[0],
            coords[1]
        );
        _dispatch(event);
        return event;
    }

    hidden function _dispatch(event as IQKitInputEvent) as Void {
        if (_focusIndex >= 0 && _focusIndex < _targets.size()) {
            var target = _targets[_focusIndex];
            target.onInput(event);
        }
    }
}
