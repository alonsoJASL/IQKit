---
title: IQKit
---

# IQKit

A Monkey C UI component library for Garmin Connect IQ round-screen devices.

## Why IQKit?

The Connect IQ SDK provides no reusable UI components. Every developer must
re-implement layout, geometry, and input handling from scratch. Here are two
concrete examples of what that looks like.

### Example 1: Arc progress bar

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

## Documentation

- [Component Library Specification](spec.md)
- [Design Decisions](design.md)

### State of the art 

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

## Letters

- [Open Letter to Garmin's Product Team](letter-garmin.md)
- [Garmin's UX Problem Is Not What You Think It Is](letter-users.md)

## Source

- [GitHub Repository](https://github.com/alonsoJASL/IQKit)
