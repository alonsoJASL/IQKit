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

## 6. Data Binding and the Stateless Contract

**Decision: Components contain no application logic, no sensor reads, and no Garmin Connect
API calls.**

A component is a rendering primitive. It receives data as arguments to `update()` or
constructor parameters. It renders that data. It does nothing else.

The watch face or app (the "orchestration layer") owns all data fetching, all sensor reads,
all timing logic, and all Garmin API calls. It calls `component.update(data)` before
triggering a redraw. The component does not know where the data came from.

This boundary is enforced at review. Any import of `Toybox.Activity`, `Toybox.SensorHistory`,
`Toybox.Weather`, or similar data APIs inside a component file is grounds for rejection.

**On the apparent conflict with "stateless" and pre-allocated instance state:**

The memory model (Section 3) requires components to pre-allocate rendering state — arrays,
computed pixel values, geometry caches — as instance variables. This looks like statefulness,
but it is not the same thing.

The distinction is: a component's *rendering state* (pre-computed pixel positions, cached arc
geometry, resolved theme tokens) is an implementation detail of the draw path. It is
deterministic — given the same `initialize()` arguments and the same `update()` call, it
produces the same output, always. It is not observable from outside the component.

*Application state* is different: it encodes decisions about the world (what sensor read,
which menu item the user last selected, what the weather API returned). Application state
belongs exclusively in the orchestration layer.

The rule, stated precisely: **a component's output is determined entirely by its
initialisation arguments and its last `update()` call.** Nothing else. Internal rendering
state that satisfies this contract is permitted and required. Internal state that violates
it — by caching external data, maintaining history, or producing different output from the
same inputs — is not.

Rationale: This is the "stateless logic engines" principle from the project's development
philosophy, applied to a memory-constrained environment. A component that obeys this contract
can be tested in the Python harness, reused across different data sources, and reasoned about
in isolation. A component that violates it cannot.

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

**Decision: `IQKit.Theme` is not a singleton or a global. It is an injected dependency.**

The natural Monkey C pattern for shared configuration is a module-level global or a static
class. `IQKit.Theme` must not follow this pattern. A global theme object means every component
has a hidden dependency on ambient state — which makes the component untestable in isolation
and makes the library's behaviour dependent on initialisation order.

Instead, theme tokens are resolved at `initialize()` time and passed explicitly:

```monkeyc
// Wrong — global theme access inside component
function draw(dc) {
    dc.setColor(IQKitTheme.PRIMARY_COLOR, IQKitTheme.BACKGROUND); // hidden global dependency
}

// Correct — theme resolved by caller, injected at initialisation
function initialize(dc, theme as IQKitThemeTokens) {
    _primaryColor = theme.primaryColor;  // stored, not fetched
    _background   = theme.background;
}

function draw(dc) {
    dc.setColor(_primaryColor, _background); // reads injected, pre-resolved state
}
```

The orchestration layer (watch face or app) is responsible for constructing and passing the
`IQKitThemeTokens` instance to each component. Components do not call `IQKit.Theme` directly.

Rationale: This is the "explicit dependency injection, no singletons, no globals" principle
from the project's development philosophy. It is not merely a style preference — a component
with a hidden global dependency cannot be instantiated with different themes, cannot be tested
without global setup, and will produce load-order bugs when multiple components initialise
concurrently.

Each component has an ID from the spec (e.g. `D-01`, `N-02`). These IDs appear as comments
in the implementation file header. This makes spec-to-code traceability explicit.

---

## 8. Component Interface Contract

Every IQKit component — without exception — exposes the following five-method public interface.
This is the single source of truth for what a component is. Anything that does not implement
this interface is not a component; it is either a utility function (belongs in `IQKit.Geometry`
or `IQKit.Layout`) or an orchestration concern (belongs in the caller).

```monkeyc
// IQKit Component Interface — mandatory for every component class

// Monkey C constructor. Called when the object is instantiated (new IQKitFoo()).
// A Dc is not available at this point. Zero-initialise all instance variables here
// so the object is in a defined state before initializeComponent() is called.
// No allocation of rendering state — that belongs in initializeComponent().
function initialize() as Void

// Called from the orchestration layer's onLayout(dc) callback, when a Dc is first
// available. Resolves all pixel dimensions from dc, stores theme tokens, and performs
// all heap allocation for rendering state. No allocation is permitted after this returns.
// config may be null — components must supply sensible defaults.
function initializeComponent(dc as Dc, theme as IQKitThemeTokens, config as IQKitFooConfig or Null) as Void

// Called by the orchestration layer when input data changes.
// Mutates pre-allocated rendering state. No allocation permitted.
// Must be idempotent: calling update(x) twice produces the same state as calling it once.
function update(data as IQKitComponentData) as Void

// Called by the OS or orchestration layer to render the component.
// No allocation. No data fetching. Reads pre-allocated state only.
function draw(dc as Dc) as Void

// Called instead of draw() when the device is in Always-On Display mode.
// Must produce ≤10% lit pixels of the component's bounding area.
// Display-only components with no light emission are exempt — but must still implement
// this method as a no-op to satisfy the interface.
function drawAod(dc as Dc) as Void
```

**Why two initialisation steps?**

Monkey C's `initialize()` method is the language constructor. It is called when the object
is allocated, which happens in the orchestration layer's own `initialize()` — before
`onLayout(dc)` fires and before a `Dc` is available. Pixel dimensions cannot be computed
without a `Dc`, so a single `initialize(dc)` is not possible in practice.

The two-step split maps directly onto the WatchFace and WatchApp lifecycle:

```monkeyc
// Orchestration layer — WatchFace or WatchApp

function initialize() {
    // Step 1: construct components — no Dc yet
    _arc  = new IQKitArcProgressBar();
    _menu = new IQKitCircularMenu();
}

function onLayout(dc as Dc) as Void {
    // Step 2: resolve dimensions and allocate rendering state
    _arc.initializeComponent(dc, _theme, null);
    _menu.initializeComponent(dc, _theme, menuConfig, items);
}
```

The no-allocation-after-init rule still holds — it applies to `initializeComponent()`, not
to `initialize()`. `initialize()` may only zero instance variables; it must not compute
geometry or allocate arrays sized from screen dimensions.

**On `IQKitComponentData`:**

Each component defines its own `IQKitComponentData` type — a structured data class, not a
positional argument list. Principle: if a component's `update()` call needs more than two
values, it needs a data class. There is no exception to this. "Magic strings" and
positional argument soup are explicitly prohibited.

```monkeyc
// Wrong — positional argument soup
component.update(72, 3, true, "bpm");

// Correct — explicit contract
var data = new IQKitArcProgressBarData(72, IQKitArcProgressBarData.UNIT_BPM, true);
component.update(data);
```

**On Builders for complex component configuration:**

When a component's `initialize()` requires more than three configuration values — zone counts,
colour arrays, angle ranges, label arrays — a Builder is required. The Builder encodes
opinionated defaults and eliminates the need for callers to supply every parameter explicitly.
The underlying data class must remain accessible for callers who need full manual control;
the Builder is a convenience layer over it, not a replacement.

```monkeyc
// Direct construction — always available
// In initialize():
_gauge = new IQKitRadialGauge();

// In onLayout(dc):
var config = new IQKitRadialGaugeConfig(
    startAngle, endAngle, zoneColors, zoneThresholds, showNeedle, labelArray
);
_gauge.initializeComponent(dc, _theme, config);

// Builder — encodes sensible defaults, overrides only what differs
// In onLayout(dc):
var config = new IQKitRadialGaugeBuilder()
    .withZones([60, 100, 140, 170, 185], IQKitThemeTokens.HR_ZONE_COLORS)
    .withNeedle(true)
    .build();
_gauge.initializeComponent(dc, _theme, config);
```

Builders are Tier 2 artefacts. They belong in the same file as the component they configure,
not in a separate builder module. The naming convention is `IQKit{ComponentName}Builder`.

**Traceability:**

Every component file begins with a header comment that records its spec ID, its interface
compliance, and its measured heap delta:

```monkeyc
// D-01 | IQKitArcProgressBar
// Interface: IQKit Component Interface v1
// Heap delta (FR970 baseline): +3.2 KB
// Author: José Alonso Solís Lemus
// Spec: docs/spec.md#d-01
```

---

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

## 10. Layered Architecture

IQKit is organised into three tiers. Every piece of code belongs to exactly one tier. If you
cannot determine which tier a new piece of code belongs to, it is a signal that the code is
doing too many things.

**Tier 1 — Utility (Foundation layer)**  
Atomic, pure functions and data structures. No component state. No Garmin API calls. No
side effects. Examples: `IQKit.Geometry` (polar-to-cartesian conversion, arc math),
`IQKit.Layout` (screen radius computation, safe-area insets), `IQKit.Theme` tokens.

A function belongs in Tier 1 if and only if it can be implemented identically in the Python
harness and in Monkey C without any platform-specific branching.

**Tier 2 — Components (Logic layer)**  
Stateful rendering primitives that implement the Component Interface Contract (Section 8).
Compose Tier 1 utilities. Emit pixels. Know nothing about data sources. Examples:
`IQKitArcProgressBar`, `IQKitCircularMenu`, `IQKitArcList`.

A class belongs in Tier 2 if it implements `initialize / update / draw / drawAod` and
contains no Garmin data API imports.

**Tier 3 — Orchestration (Interface layer / Reference implementations)**  
Watch faces, widgets, and device apps that consume Tier 2 components. Own all data fetching,
all sensor reads, all timing, all Garmin Connect API calls. The orchestration layer is not
part of the library — it is the consumer of the library. The reference implementations
(`R-01`, `R-02` in the spec) are Tier 3 artefacts.

**The Rule of Three for Tier 1 additions:**  
A utility function is not added to `IQKit.Geometry` or `IQKit.Layout` because it is useful.
It is added when three distinct components require the same logic independently. Before that
threshold, the function lives inside the component that needs it, prefixed with `_`. Code
duplication at the component level is cheaper than a premature utility abstraction that
constrains future component design.

This rule applies exclusively to Tier 1. Tier 2 components are added according to the spec
catalogue; they do not require a Rule of Three justification.

---

## 11. Testing and Validation

**Decision: The Python harness is the living documentation of component behaviour.**

The Python harness (`/harness/`) is not merely a prototyping tool. It is the canonical
readable demonstration of what each component does and how it behaves across device profiles.
A developer reading the harness should be able to understand the component's full behaviour —
its geometry, its edge cases, its AOD variant — without reading the Monkey C source.

This means harness renderings are reviewed as code, not as screenshots. They must cover the
component's full parameter range (minimum values, maximum values, typical values), all target
device profiles in the Tier 1 matrix, and both active and AOD rendering modes.

A component's harness is considered complete when a developer unfamiliar with the component
can look at the harness output alone and write a correct Monkey C implementation. That is the
bar — not "it renders something reasonable."

**Decision: Every component has a reviewed harness rendering before Monkey C implementation
begins.**

No Monkey C implementation is started until the harness rendering for that component has been
reviewed and accepted. This is the design validation gate. Geometry errors, layout assumptions,
and AOD pixel budget violations caught in the harness cost minutes to fix. The same errors
caught in the CIQ simulator cost hours.

**Decision: The canonical test device for Phase 1 is the Forerunner 970 (454×454 AMOLED).**

All components must pass visual review in the CIQ simulator using the FR970 device profile
before any other profile is tested. Cross-device testing uses the Fenix 8 (454×454) and
Venu 4 profiles as the secondary and tertiary targets.

**Decision: Memory usage must be documented per component.**

Each component's documentation block must include a measured heap delta from a baseline empty
watch face, obtained from the CIQ simulator memory profiler. This is recorded at initial
implementation and updated if the component's state model changes.

---

## 12. What Is Not Decided Here

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