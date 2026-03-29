// IQKit -- Barrel manifest / entry point
// Phase 0: Foundation modules only.
//
// This file is the barrel entry point for the IQKit library.
// Include this in your project's jungle file to pull in all IQKit modules.
//
// Usage in a Monkey C project:
//   Add IQKit as a barrel dependency in your monkey.jungle:
//   base.barrelPath = $(base.barrelPath);../IQKit/src

using Toybox.Lang;
using Toybox.Math;
using Toybox.Graphics;
using Toybox.WatchUi;
using Toybox.Timer;

// Tier 1 -- Foundation
// F-01: Geometry (polar-to-cartesian, arc math, polygon helpers)
// F-02: Theme (colour palette, font size tokens, stroke weight tokens)
// F-03: Layout (screen radius, safe-area insets, radial grid)
// F-04: InputRouter (unified event dispatcher, focus management)
//
// Source files in foundation/ are auto-included by the compiler when this
// barrel is referenced. The using directives above make Toybox modules
// available to all foundation code.

// Tier 2 -- Components (Phase 1)
// D-01: ArcProgressBar (single-value arc indicator, AOD variant)
// D-03: CentreMetric (large value + unit label, AOD variant)
// N-01: CircularMenu (radial item layout, max 8 items)
// N-02: ArcList (chord-width constrained scrollable list)
// N-05: ConfirmDialog (binary confirm/cancel, two-button layout)
