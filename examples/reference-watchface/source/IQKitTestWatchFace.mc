// IQKit Phase 1 Reference Watch Face
// Exercises all five Phase 1 components in the CIQ simulator.
//
// Mode navigation (from the face, mode 0):
//   ENTER  → CircularMenu (N-01)
//   DOWN   → ArcList (N-02)
//   UP     → ConfirmDialog (N-05)
//
// From any interactive mode:
//   BACK       → return to face
//   UP / DOWN  → navigate within the component
//   ENTER      → select (also returns to face on a confirmed selection)

using Toybox.Application;
using Toybox.Graphics;
using Toybox.WatchUi;
using Toybox.Lang;

// ---------------------------------------------------------------------------
// App entry point
// ---------------------------------------------------------------------------

class IQKitTestApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Lang.Dictionary or Null) as Void {
    }

    function onStop(state as Lang.Dictionary or Null) as Void {
    }

    function getInitialView() as [WatchUi.Views] or [WatchUi.Views, WatchUi.InputDelegates] {
        var view = new IQKitTestView();
        var delegate = new IQKitTestDelegate(view);
        return [view, delegate];
    }
}

// ---------------------------------------------------------------------------
// View
// ---------------------------------------------------------------------------

class IQKitTestView extends WatchUi.WatchFace {

    hidden var _theme   as IQKitThemeTokens;
    hidden var _arc     as IQKitArcProgressBar;
    hidden var _metric  as IQKitCentreMetric;
    hidden var _menu    as IQKitCircularMenu;
    hidden var _list    as IQKitArcList;
    hidden var _dialog  as IQKitConfirmDialog;
    hidden var _mode    as Lang.Number;  // 0=face  1=menu  2=list  3=dialog

    function initialize() {
        WatchFace.initialize();
        _theme  = new IQKitThemeTokens({});
        _arc    = new IQKitArcProgressBar();
        _metric = new IQKitCentreMetric();
        _menu   = new IQKitCircularMenu();
        _list   = new IQKitArcList();
        _dialog = new IQKitConfirmDialog();
        _mode   = 0;
    }

    // All allocation happens here. onUpdate() allocates nothing.
    function onLayout(dc as Graphics.Dc) as Void {
        // D-01 ArcProgressBar — 72% fill, default 135–405° sweep.
        _arc.initializeComponent(dc, _theme, null);
        _arc.update(0.72f);

        // D-03 CentreMetric — static seed value.
        _metric.initializeComponent(dc, _theme);
        _metric.update("72", "bpm");

        // N-01 CircularMenu — four activity types.
        var menuItems = [
            new IQKitCircularMenuItem("Run"),
            new IQKitCircularMenuItem("Bike"),
            new IQKitCircularMenuItem("Swim"),
            new IQKitCircularMenuItem("Hike"),
        ] as Lang.Array<IQKitCircularMenuItem>;
        _menu.initializeComponent(
            dc, _theme,
            new IQKitCircularMenuConfig({:title => "Start"}),
            menuItems
        );

        // N-02 ArcList — five recent activities.
        _list.initializeComponent(dc, _theme, null);
        var listItems = [
            new IQKitArcListItem("Morning Run",       "5.2 km"),
            new IQKitArcListItem("Afternoon Bike",    "22.1 km"),
            new IQKitArcListItem("Evening Walk",      "1.8 km"),
            new IQKitArcListItem("Swim Session",      "1500 m"),
            new IQKitArcListItem("Strength Training", "45 min"),
        ] as Lang.Array<IQKitArcListItem>;
        _list.update(listItems);

        // N-05 ConfirmDialog.
        _dialog.initializeComponent(
            dc, _theme,
            new IQKitConfirmDialogConfig({
                :promptText   => "End Activity?",
                :confirmLabel => "Yes",
                :cancelLabel  => "No",
            })
        );
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(_theme.background, _theme.background);
        dc.clear();

        if (_mode == 0) {
            _arc.draw(dc);
            _metric.draw(dc);
        } else if (_mode == 1) {
            _menu.draw(dc);
        } else if (_mode == 2) {
            _list.draw(dc);
        } else {
            _dialog.draw(dc);
        }
    }

    // Called by IQKitTestDelegate. Returns true if the event was consumed.
    function onInputKey(keyEvent as WatchUi.KeyEvent) as Lang.Boolean {
        var key = keyEvent.getKey();

        // Face mode: three buttons map to the three interactive components.
        if (_mode == 0) {
            if      (key == WatchUi.KEY_ENTER) { _mode = 1; }
            else if (key == WatchUi.KEY_DOWN)  { _mode = 2; }
            else if (key == WatchUi.KEY_UP)    { _mode = 3; }
            else { return false; }
            WatchUi.requestUpdate();
            return true;
        }

        // BACK always returns to the face from any interactive mode.
        if (key == WatchUi.KEY_ESC) {
            _mode = 0;
            WatchUi.requestUpdate();
            return true;
        }

        // Translate key to IQKitInputAction; ignore unmapped keys.
        var action = -1;
        if      (key == WatchUi.KEY_UP)    { action = IQKIT_ACTION_UP; }
        else if (key == WatchUi.KEY_DOWN)  { action = IQKIT_ACTION_DOWN; }
        else if (key == WatchUi.KEY_ENTER) { action = IQKIT_ACTION_ENTER; }
        if (action < 0) { return false; }

        var event = new IQKitInputEvent(
            IQKIT_INPUT_KEY,
            action as IQKitInputAction,
            null,
            null
        );

        if (_mode == 1) {
            _menu.onInput(event);
            if (_menu.getSelectedIndex() >= 0) { _mode = 0; }
        } else if (_mode == 2) {
            _list.onInput(event);
            if (_list.getSelectedIndex() >= 0) { _mode = 0; }
        } else if (_mode == 3) {
            _dialog.onInput(event);
            if (_dialog.getResult() != IQKIT_DIALOG_PENDING) { _mode = 0; }
        }

        WatchUi.requestUpdate();
        return true;
    }
}

// ---------------------------------------------------------------------------
// Delegate
// ---------------------------------------------------------------------------

class IQKitTestDelegate extends WatchUi.WatchFaceDelegate {

    hidden var _view as IQKitTestView;

    function initialize(view as IQKitTestView) {
        WatchFaceDelegate.initialize();
        _view = view;
    }

    function onKeyPressed(keyEvent as WatchUi.KeyEvent) as Lang.Boolean {
        return _view.onInputKey(keyEvent);
    }
}
