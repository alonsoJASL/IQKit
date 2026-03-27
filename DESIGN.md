# IQKit — Design Decisions

**Status:** LOCKED for Phase 0 and Phase 1  
**Last revised:** March 2026  
**Author:** José Alonso Solís Lemus

---

This document records the architectural decisions that govern IQKit. These decisions are not
proposals, not discussion items, and not subject to community vote during Phase 0 and Phase 1.
They exist because a library without locked foundations is a library that cannot be built —
every architectural question left open becomes a blocker on every component PR.

If you disagree with a decision here, open an issue tagged `design-question` after Phase 1 is
complete (see `CONTRIBUTING.md` for the exact trigger). Design PRs opened against locked
decisions will be closed without review.

---

## 1. Language and Platform

**Decision: Monkey C only. No transpiler, no wrapper layer.**

IQKit targets the Garmin Connect IQ SDK natively. There is no transpilation layer, no code
generation step, and no abstraction over the Monkey C runtime. The library ships as Monkey C
source that developers include directly in their projects.

Rationale: A transpiler would add build complexity, obscure heap behaviour, and create a
maintenance surface that cannot be sustained by a small team. The value of the library is
precisely that it runs on the same constrained runtime as the code that calls it — and the
author must feel that constraint directly when designing components.

**Decision: Minimum API level 6.x.**

All components must compile and run correctly on Connect IQ API level 6.x or higher. Features
from API 7.x and 8.x may be used conditionally, gated behind `Toybox.System.getDeviceSettings()`
capability checks, but they must degrade gracefully on API 6.x devices. Components may not
hard-require API 7.x or 8.x.

Rationale: API 6.x covers the Epix Pro Gen 2, Forerunner 265, Venu 3, and Vivoactive 5 — a
substantial portion of the active round-screen device population. Cutting them off at launch
reduces the library's relevance and the pool of potential contributors who can test on hardware.

---

## 2. Coordinate System

**Decision: All dimensions are expressed as fractions of a screen dimension token, never as
raw pixel integers.**

For round screens: the base unit is `screenRadius`, defined as `Math.floor(dc.getWidth() / 2)`.  
For rectangular screens (Phase 2): the base units will be `screenWidth` and `screenHeight`.

All fractional values are resolved to integer pixels exactly once, in `initialize()`, and stored
as instance variables. No floating-point arithmetic occurs inside `draw()`.

```monkeyc
// Correct
var _arcThickness;

function initialize(dc) {
    _arcThickness = (dc.getWidth() / 2 * 0.08).toNumber();
}

function draw(dc) {
    dc.setPenWidth(_arcThickness); // integer, pre-computed
}

// Wrong
function draw(dc) {
    dc.setPenWidth((dc.getWidth() / 2 * 0.08).toNumber()); // allocation + float in draw path
}
```

Rationale: This is not a style preference. Floating-point operations in `draw()` on constrained
devices produce measurable frame drops. Pre-computing to integers eliminates this at zero
architectural cost.

**Decision: Polar coordinates are the primary layout model for round-screen components.**

Positions are specified as `(angle, radius)` pairs relative to screen centre, not as `(x, y)`
pixel offsets. The `IQKit.Geometry` module provides `polarToCartesian(cx, cy, r, angleDeg)`
as the canonical conversion. Callers who need pixel coordinates call this function explicitly;
components never accept raw pixel positions as their primary interface.

Rationale: Polar coordinates map directly to the round screen's geometry. A component
positioned at `(270°, 0.6r)` reads as "bottom, 60% of the way to the edge" — which is
understandable. The same position expressed as `(227, 341)` on a 454×454 screen is opaque
and does not scale.

---

## 3. Memory Model

**Decision: No heap allocation in `draw()` or any method called by `draw()`.**

This is a hard rule. Violation of this rule will cause a PR to be rejected regardless of other
quality. The permitted pattern is: allocate in `initialize()`, mutate pre-allocated state in
`update()`, read pre-allocated state in `draw()`.

```monkeyc
// Correct: array allocated once
var _points;

function initialize(dc) {
    _points = new [8]; // allocated once
}

function update(value) {
    _points[0] = value; // mutates, no allocation
}

function draw(dc) {
    dc.fillPolygon(_points); // reads pre-allocated array
}

// Wrong: array allocated on every draw call
function draw(dc) {
    var pts = [x0, y0, x1, y1, x2, y2, x3, y3]; // allocates on every frame
    dc.fillPolygon(pts);
}
```

Rationale: Garmin's watch OS does not have a generational garbage collector. Every allocation
in `draw()` is a potential GC pause on the next frame. On a 1Hz watch face this is tolerable;
on an activity app running at higher frequency it causes visible stuttering. The rule is
absolute because "only allocate small things in draw()" is not a rule — it is a negotiation
that will be lost.

**Decision: Components do not own resources. Bitmaps, fonts, and external data are passed in.**

A component never loads a bitmap, reads a sensor, or calls a Garmin API for external data.
If a component needs an icon, the caller provides a pre-loaded `BitmapResource`. This is not
optional.

Rationale: Resource loading is expensive and belongs in the orchestration layer (the watch face
or app). If components load their own resources, they compete with each other for heap during
initialisation, producing load-order bugs that are extremely difficult to debug on-device.

---

## 4. Input Model

**Decision: Every interactive component supports button navigation as a first-class input
method, not a fallback.**

Touch is not available on all round-screen Garmin devices (the Instinct 3 AMOLED has no
touchscreen), is disabled during swim activities across all devices, and is unreliable in rain
or with gloves. A component that requires touch to function is incomplete by definition.

The dual-input contract is:
- Touch: direct selection by tap coordinate hit-testing
- Buttons: UP/DOWN to move focus, ENTER to select, BACK to cancel or dismiss
- Focus state is a visual property of the component, not managed by the caller

Components that have no interactive state (display-only) are exempt from this requirement.

**Decision: Long-press is implemented via `Timer`, not assumed as a platform event.**

Monkey C does not provide a native long-press event. Components that need long-press behaviour
must implement it using `Toybox.Timer` internally. The threshold is 600ms unless the component
documentation specifies otherwise. Long-press is a P2 feature — no P0 or P1 component requires
it.

---

## 5. Always-On Display (AOD)

**Decision: Every component that emits light must have an AOD variant.**

The rule is simple: if a component has a `draw(dc)` method, it must also have a `drawAod(dc)`
method. The AOD variant must produce a rendering where total lit pixels are ≤10% of the
component's bounding area, measured against a black background.

The caller is responsible for choosing which method to call. The component is responsible for
what each method draws. There is no automatic switching.

```monkeyc
// Component interface contract
function draw(dc) {
    // Full-colour active rendering
}

function drawAod(dc) {
    // Reduced-pixel AOD rendering — ≤10% lit pixels
}
```

Rationale: The 10% threshold comes from Garmin's own AMOLED AOD guidelines for older devices.
Newer devices are more permissive, but designing to the stricter constraint ensures the
library works across the full target matrix without per-device conditionals.

---

## 6. Data Binding

**Decision: Components contain no application logic, no sensor reads, and no Garmin Connect
API calls.**

A component is a rendering primitive. It receives data as arguments to `update()` or
constructor parameters. It renders that data. It does nothing else.

The watch face or app (the "orchestration layer") owns all data fetching, all sensor reads,
all timing logic, and all Garmin API calls. It calls `component.update(data)` before
triggering a redraw. The component does not know where the data came from.

This boundary is enforced at review. Any import of `Toybox.Activity`, `Toybox.SensorHistory`,
`Toybox.Weather`, or similar data APIs inside a component file is grounds for rejection.

Rationale: This is not NIH ("not invented here") purism. It is the direct equivalent of the
"stateless logic engines" principle in the project's development philosophy. A component with
embedded data logic cannot be tested in the Python harness, cannot be reused across different
data sources, and creates hidden dependencies that make the library unpredictable.

---

## 7. Naming and Module Convention

**Decision: All public symbols are prefixed with `IQKit`.**

Monkey C has a flat module system with no package namespacing equivalent to Java or Python.
The `IQKit` prefix is the namespace. All classes, modules, and public functions exported by
the library begin with `IQKit`.

```monkeyc
// Correct
class IQKitArcProgressBar { ... }
module IQKitGeometry { ... }

// Wrong
class ArcProgressBar { ... }    // pollutes caller's namespace
class Iqkit_ArcProgressBar { } // inconsistent casing
```

**Decision: Internal symbols use a leading underscore.**

Variables and methods not intended for external use are prefixed with `_`. This is a
convention, not enforced by the language, but it is enforced by code review.

**Decision: Component IDs from the spec are preserved in code.**

Each component has an ID from the spec (e.g. `D-01`, `N-02`). These IDs appear as comments
in the implementation file header. This makes spec-to-code traceability explicit.

---

## 8. Testing and Validation

**Decision: Every component has a Python harness reference rendering before Monkey C
implementation begins.**

The Python harness (`/harness/`) renders each component using the same coordinate model and
the same device profiles as the Monkey C implementation. A component is not considered ready
for Monkey C implementation until its harness rendering has been reviewed and approved.

This is not optional. The harness is not documentation — it is the design validation step that
catches geometry errors before they are expensive to fix in the simulator.

**Decision: The canonical test device for Phase 1 is the Forerunner 970 (454×454 AMOLED).**

All components must pass visual review in the CIQ simulator using the FR970 device profile
before any other profile is tested. Cross-device testing uses the Fenix 8 (454×454) and Venu 4
profiles as the secondary and tertiary targets.

**Decision: Memory usage must be documented per component.**

Each component's documentation block must include a measured heap delta from a baseline empty
watch face, obtained from the CIQ simulator memory profiler. This is recorded at initial
implementation and updated if the component's state model changes.

---

## 9. What Is Not Decided Here

The following questions are deliberately left open. They will be decided when Phase 1 is
complete and the contribution process opens:

- Whether Phase 2 rectangular-screen components share class hierarchies with round-screen
  components or are parallel implementations
- Whether the Python harness becomes a standalone published tool or remains a development
  utility
- Theming API beyond the `IQKit.Theme` token system (e.g. runtime theme switching)
- Whether `IQKit.InputRouter` should support multi-component focus trees (tab order across
  multiple components on a single screen)

These are not open because they are unimportant. They are open because deciding them now,
before Phase 1 exists, would be speculation dressed as architecture.