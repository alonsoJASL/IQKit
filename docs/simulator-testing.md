# IQKit Phase 1 Simulator Testing

How to build and validate all Phase 1 components in the Garmin CIQ simulator.
This is the gate that must pass before Phase 2 begins.


## Prerequisites

- Garmin Connect IQ SDK 9.1.0 installed at `~/.Garmin/ConnectIQ/`
- Developer key at `~/.Garmin/ConnectIQ/Key/developer_key`
- The IQKit repo checked out — this guide assumes you are working from the repo root

Add these to your shell profile so the commands below stay readable:

```bash
export CIQ_BIN=~/.Garmin/ConnectIQ/Sdks/connectiq-sdk-lin-9.1.0-2026-03-09-6a872a80b/bin
export CIQ_KEY=~/.Garmin/ConnectIQ/Key/developer_key
```


## What the test app is

`examples/reference-watchface/` is a minimal Monkey C watch face that exercises
all five Phase 1 components in a single build. It is not a product; it exists
only as a validation vehicle.

Components exercised:
- D-01 IQKitArcProgressBar (display)
- D-03 IQKitCentreMetric (display)
- N-01 IQKitCircularMenu (interactive)
- N-02 IQKitArcList (interactive)
- N-05 IQKitConfirmDialog (interactive)


## Project structure

```
examples/reference-watchface/
├── manifest.xml
├── monkey.jungle
├── resources/
│   ├── drawables/
│   │   ├── drawables.xml       # declares LauncherIcon bitmap
│   │   └── launcher_icon.png   # borrowed from SDK sample; replace if desired
│   └── strings/
│       └── strings.xml         # defines AppName string resource
└── source/
    └── IQKitTestWatchFace.mc   # App, view, and delegate
```

IQKit ships as source, not a pre-compiled barrel. `sourcePath` (not
`barrelPath`) is used, with all three tiers listed explicitly because
`sourcePath` is non-recursive:

```
base.sourcePath = $(base.sourcePath);../../src;../../src/foundation;../../src/components
```


## Building from the terminal

```bash
mkdir -p examples/reference-watchface/bin
$CIQ_BIN/monkeyc \
  -f examples/reference-watchface/monkey.jungle \
  -d fr970 \
  -o examples/reference-watchface/bin/IQKitTestWatchFace.prg \
  -y $CIQ_KEY
```

A clean build exits with no output and produces the `.prg` file. Warnings can
be enabled with `-w` but are not required to pass.

To build for a different device, replace `-d fr970` with the target device ID.
Valid IDs are the directory names under `~/.Garmin/ConnectIQ/Devices/`:

```bash
ls ~/.Garmin/ConnectIQ/Devices/
```


## Building in VS Code

1. Open the **IQKit repo root** as a VS Code workspace.
2. Command Palette (`Ctrl+Shift+P`) → **"Monkey C: Build Current Project"**.
3. Select `examples/reference-watchface/monkey.jungle` and then `fr970`.
4. A successful build produces no errors in the Output panel.


## Running in the simulator

```bash
$CIQ_BIN/connectiq &   # start the simulator if not already running
$CIQ_BIN/monkeydo examples/reference-watchface/bin/IQKitTestWatchFace.prg fr970
```

Or from VS Code: Command Palette → **"Monkey C: Run on Simulator"**.


## Key mapping in the simulator

| Simulator button    | Physical key | What it does in this app                          |
|---------------------|-------------|---------------------------------------------------|
| UP (top-left)       | KEY_UP      | Face: open ConfirmDialog / Interactive: navigate up |
| DOWN (bottom-left)  | KEY_DOWN    | Face: open ArcList / Interactive: navigate down   |
| START (top-right)   | KEY_ENTER   | Face: open CircularMenu / Interactive: select     |
| BACK (bottom-right) | KEY_ESC     | Interactive: return to face                       |

Touch is also available on AMOLED profiles — tap a component item to select it.


## Pass criteria

A failure is any crash, blank screen, or missing element — not cosmetic pixel
differences between devices.

### Mode 0 — Face (default on launch)
- [ ] ArcProgressBar renders as a green arc at ~70% screen radius
- [ ] Fill covers about 72% of the sweep
- [ ] CentreMetric shows "72" in large text and "bpm" below it
- [ ] No overlap between the two components

### Mode 1 — CircularMenu (press START from face)
- [ ] Four item circles arranged evenly around the screen centre
- [ ] Labels "Run", "Bike", "Swim", "Hike" visible
- [ ] One ring highlighted in accent colour (green) — that is focus
- [ ] UP / DOWN moves focus around the ring
- [ ] START on a focused item returns to the face

### Mode 2 — ArcList (press DOWN from face)
- [ ] Five list items visible, text narrowing near screen edges
- [ ] One row highlighted — that is focus
- [ ] UP / DOWN moves focus and scrolls
- [ ] START on a focused item returns to the face

### Mode 3 — ConfirmDialog (press UP from face)
- [ ] Prompt "End Activity?" visible
- [ ] Two circular buttons: "Yes" and "No"
- [ ] UP / DOWN toggles focus between buttons
- [ ] START on a focused button returns to the face

### BACK from any interactive mode
- [ ] Returns to the face from modes 1, 2, and 3


## Repeating on additional devices

Once fr970 passes, repeat on:
1. **fenix847mm** — 416×416. Verify components scale correctly.
2. **venu series** — check `ls ~/.Garmin/ConnectIQ/Devices/ | grep venu` for the
   exact installed ID, add it to `manifest.xml`, and rebuild.

Change the `-d` flag to the new device ID for each build.


## Manifest rules (hard-won)

The Garmin manifest schema is strict in non-obvious ways. These all caused build
failures and are now correct in the committed `manifest.xml`:

- `type="watchface"` — all lowercase. `watchFace` is rejected.
- `name="@Strings.AppName"` — must be a string resource reference. A plain
  string like `"My App"` is rejected.
- `minSdkVersion` — not `minApiLevel`.
- `launcherIcon="@Drawables.LauncherIcon"` — required; omitting it is an error.
- UUID in `id` has no dashes: `a4b8c2d6e1394f87a2359d3b17c580e1`.
- No `launchLabel` attribute — it does not exist in this schema version.
- Device IDs in `<iq:product>` must match exactly what is installed in the SDK.
  Check with `ls ~/.Garmin/ConnectIQ/Devices/`.


## Troubleshooting

**Simulator shows a blank screen**
Watch faces only update when the simulator clock ticks. Press any button or
wait a few seconds for the first `onUpdate` call.

**"Symbol not found" compile error naming an IQKit class**
The barrel path `../../src` in `monkey.jungle` is not resolving. Confirm
`src/IQKit.mc` exists at the repo root.

**Key presses do nothing in the simulator**
Click the simulator window to give it keyboard focus before pressing keys.
On Linux this step is required.

**"Device does not support API level"**
The `minSdkVersion` in `manifest.xml` is higher than what the installed device
profile supports. Lower it or install a newer device profile via the SDK Manager.
