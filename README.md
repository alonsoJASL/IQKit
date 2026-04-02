# IQKit

A Monkey C UI component library for Garmin Connect IQ round-screen devices.

IQKit provides reusable, allocation-free rendering components designed for
circular AMOLED and MIP displays. All layout uses polar coordinates and
fractional screen dimensions -- no hard-coded pixel values.

**Status:** Phase 1 complete -- simulator-validated on fr970. Phase 1 exit criterion (multi-device validation) in progress.

## Quick Start (Python Harness)

The Python harness validates component geometry before Monkey C implementation.

```
conda create -n iqkit python=3.10
conda activate iqkit
pip install -e harness/
python -m harness.preview
```

## Project Structure

```
harness/          Python design harness (pygame renderer, device profiles)
src/foundation/   Tier 1: Geometry, Layout, Theme, InputRouter (Monkey C)
src/components/   Tier 2: Display and navigation components (Monkey C)
examples/         Tier 3: Reference watch face and widget
docs/             Specification, design letters, GitHub Pages
```

## Architecture

Three tiers, strict boundaries:

- **Tier 1 -- Foundation**: Pure math and data. No Garmin API calls. Identical
  implementations in Python (harness) and Monkey C (src).
- **Tier 2 -- Components**: Rendering primitives with a four-method contract:
  `initialize(dc)`, `update(data)`, `draw(dc)`, `drawAod(dc)`. Zero heap
  allocation in draw path. Dual input (touch + buttons).
- **Tier 3 -- Orchestration**: Watch faces and widgets that consume components.
  Own all data fetching and sensor reads. Not part of the library.

See [DESIGN.md](DESIGN.md) for locked architectural decisions.

## Documentation

- [Component Library Specification](docs/spec.md)
- [Design Decisions](DESIGN.md)
- [Contributing Guide](CONTRIBUTING.md)
- [Open Letter to Garmin](docs/letter-garmin.md)
- [Letter to Users](docs/letter-users.md)

## Target Devices

Phase 1 targets round-screen Garmin devices across Forerunner, Fenix, Epix,
Venu, Vivoactive, and Instinct lines. Minimum API level 6.x.

Primary test device: Forerunner 970 (454x454 AMOLED).

## Why IQKit?

The Connect IQ SDK provides no reusable UI components. Every developer must
re-implement layout, geometry, and input handling from scratch. Here are two
concrete examples of what that looks like.

### Arc progress bar

Without IQKit, drawing a filled arc ring requires manual trigonometry, polygon
construction, and careful memory discipline (no allocation in the draw path):

```monkeyc
// Without IQKit -- inside onLayout or a helper function
using Toybox.Math;
var r         = dc.getWidth() / 2;
var cx        = dc.getWidth() / 2;
var cy        = dc.getHeight() / 2;
var midR      = (r * 0.72).toNumber();     // magic fraction
var halfThick = (r * 0.04).toNumber();     // magic fraction
var rInner    = midR - halfThick;
var rOuter    = midR + halfThick;

// Build track polygon -- trig loop you must write yourself (~25 lines)
var numSegs   = 72;
var trackPoly = new Lang.Array< Lang.Array<Lang.Number> >[numSegs * 2 + 2];
// ... arc math ...

// Build fill polygon for 72% progress -- same loop, different end angle
var fillEnd  = 135.0f + 0.72f * 270.0f;
var fillSegs = (numSegs * 0.72f).toNumber();
var fillPoly = new Lang.Array< Lang.Array<Lang.Number> >[fillSegs * 2 + 2];
// ... same arc math again ...

// In onUpdate:
dc.setColor(0x3C3C3C, 0x000000);
dc.fillPolygon(trackPoly as Lang.Array<Graphics.Point2D>);
dc.setColor(0x00C850, 0x000000);
dc.fillPolygon(fillPoly as Lang.Array<Graphics.Point2D>);
```

With IQKit:

```monkeyc
// In onLayout:
_arc.initializeComponent(dc, _theme, null);
_arc.update(0.72f);

// In onUpdate:
_arc.draw(dc);
```

The geometry math, polygon memory, no-alloc rule, and device scaling are all
handled by the library and validated by the Python harness across device profiles.

### Circular menu

Without IQKit, a radial menu requires computing item positions, tracking focus
state, and writing a hit-test function by hand:

```monkeyc
// Without IQKit
var items  = ["Run", "Bike", "Swim", "Hike"];
var ringR  = (r * 0.52).toNumber();
var itemR  = (r * 0.12).toNumber();
var itemX  = new Lang.Array<Lang.Number>[4];
var itemY  = new Lang.Array<Lang.Number>[4];
for (var i = 0; i < 4; i++) {
    var a = Math.toRadians(270.0 + i * 90.0);
    itemX[i] = cx + (ringR * Math.cos(a)).toNumber();
    itemY[i] = cy + (ringR * Math.sin(a)).toNumber();
}
var focusIndex = 0;
// ... draw loop: fillCircle + drawCircle + drawText per item ...
// ... key handler: focusIndex = (focusIndex +/- 1) % 4 ...
// ... hit test: manual distance-squared check per item ...
```

With IQKit:

```monkeyc
// In onLayout:
_menu.initializeComponent(dc, _theme,
    new IQKitCircularMenuConfig({:title => "Start"}),
    [new IQKitCircularMenuItem("Run"), ...]);

// Input handling:
_menu.onInput(event);
if (_menu.getSelectedIndex() >= 0) { /* handle selection */ }
```

### Prior art

The gap IQKit fills has been documented but not closed:

- [garmin/connectiq-apps](https://github.com/garmin/connectiq-apps) — Garmin's official
  sample collection. App-type examples and Monkey Barrel references; no UI components.
- [douglasr/connectiq-samples](https://github.com/douglasr/connectiq-samples) — the most
  substantive community effort: utility snippets and ad-hoc library code. No shared interface
  contract, no coordinate-system abstraction, no form-factor design language.
- [bombsimon/awesome-garmin](https://github.com/bombsimon/awesome-garmin) — the community
  project index. No entry for a UI component library.
- [Connect IQ developer forum](https://forums.garmin.com/developer/connect-iq/f/discussion/303170/)
  — a developer explicitly names the missing abstraction: "UI components need more ways to
  inspect them."

Full analysis is in [docs/spec.md](docs/spec.md#11-prior-art-and-landscape-survey).

---

## License

MIT. See [LICENSE](LICENSE).
