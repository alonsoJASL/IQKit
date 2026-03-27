# IQKit — Component Library Specification
**Version:** 0.1-DRAFT  
**Status:** Pre-implementation — scope review  
**Purpose:** Establish a shared, open-source Monkey C UI component library for Garmin Connect IQ
devices, addressing the absence of native shared primitives in the Connect IQ SDK. The library is
designed to be device-shape-agnostic; Phase 1 targets round screens exclusively, with rectangular
and semi-octagon device support as a planned extension.

---

## 1. Problem Statement

The Connect IQ SDK provides no reusable UI components. Every developer — including Garmin's own
teams — must re-implement menus, dialogs, progress indicators, and layout primitives from scratch
using a low-level 2D graphics API. The consequences are:

- Inconsistent interaction patterns across apps on the same device
- Layout assumptions that ignore the physical screen shape — on round devices this wastes ~22%
  of visible area in the corners of a 454×454 display; on square devices it produces awkward
  padding and visual imbalance at bezel boundaries
- Configuration debt: users invest hours customising around bad defaults, then resist updates
  because their configuration breaks
- High barrier to entry for third-party developers producing quality apps

This library is both a practical tool and a demonstrable proof-of-concept for what Garmin should
have shipped as platform infrastructure.

---

## 2. Scope

### In scope
- Monkey C component library targeting all Garmin Connect IQ devices (shape-agnostic
  architecture)
- Python-based design/test harness for layout prototyping before Monkey C port
- Reference watch face and reference widget using library components
- Developer documentation and contribution guide

### Phase 1 target (this document)
Round-screen devices only — AMOLED and MIP. The coordinate system and component contracts are
designed from the start to accommodate non-round shapes; square and semi-octagon device support
is a planned Phase 2 extension, not a retrofit.

### Out of scope for Phase 1
- Rectangular screen devices (Venu Sq, Vivoactive sq, Edge computers) — architecture
  accommodates them; implementation is deferred
- Semi-octagon screen devices (older Instinct series) — deferred to Phase 2
- Replacement or modification of native Garmin OS menus
- Network/API integration components
- Font rendering (deferred — Monkey C font API is extremely limited)
- Animation framework (deferred — heap cost is prohibitive on constrained devices)

---

## 3. Target Device Matrix — Phase 1 (Round Screens)

All devices listed here share a round screen form factor. The matrix covers the active Garmin
lineup as of early 2026 across Forerunner, Fenix, Epix, Tactix, Venu, Vivoactive, Descent, and
Instinct lines. Square-screen variants of these families (e.g. Venu Sq, Vivoactive sq) are
excluded from Phase 1 but are accounted for in the coordinate system design.

### Tier 1 — Primary targets (AMOLED, 454×454, touch + buttons)
These share identical resolution and display technology across multiple Garmin lines. Full
library support.

| Device                       | Line       | Release | API Level | Touch | Heap (approx.) |
| ---------------------------- | ---------- | ------- | --------- | ----- | -------------- |
| Forerunner 970               | Forerunner | 2025    | 8.x       | Yes   | ~1MB           |
| Forerunner 965               | Forerunner | 2023    | 7.x       | Yes   | ~1MB           |
| Fenix 8 AMOLED (47mm / 51mm) | Fenix      | 2024    | 7.x       | Yes   | ~1MB           |
| Fenix 8 Pro AMOLED           | Fenix      | 2025    | 8.x       | Yes   | ~1MB           |
| Epix Pro Gen 2 (42/47/51mm)  | Epix       | 2023    | 6.x       | Yes   | ~1MB           |
| Tactix 8 AMOLED              | Tactix     | 2024    | 7.x       | Yes   | ~1MB           |
| Descent Mk3 AMOLED           | Descent    | 2023    | 7.x       | Yes   | ~1MB           |
| Venu X1                      | Venu       | 2025    | 8.x       | Yes   | ~1MB           |

### Tier 2 — Secondary targets (AMOLED / MIP, smaller resolution, touch + buttons)
Same architecture, varying resolution. Components scale via coordinate normalisation.

| Device                | Line       | Release | API Level | Touch | Notes                                      |
| --------------------- | ---------- | ------- | --------- | ----- | ------------------------------------------ |
| Forerunner 265 / 265S | Forerunner | 2023    | 6.x       | Yes   | 265S: 360×360                              |
| Forerunner 165        | Forerunner | 2024    | 6.x       | Yes   | 240×240 — watch face only                  |
| Venu 4 / 4S           | Venu       | 2025    | 8.x       | Yes   | 4S smaller radius                          |
| Venu 3 / 3S           | Venu       | 2023    | 6.x       | Yes   | 3S: 390×390                                |
| Vivoactive 5          | Vivoactive | 2023    | 6.x       | Yes   | 390×390                                    |
| Instinct 3 AMOLED     | Instinct   | 2025    | 7.x       | No    | AMOLED without touch — important edge case |

### Tier 3 — Stretch targets (MIP round, buttons only)
Color-limited (8-bit or greyscale), no touch. Reduced component set — display components only,
no touch-dependent navigation components.

| Device                     | Line       | Display   | Resolution | Notes        |
| -------------------------- | ---------- | --------- | ---------- | ------------ |
| Fenix 8 Solar              | Fenix      | MIP Color | 280×280    | Buttons only |
| Forerunner 955 / 955 Solar | Forerunner | MIP Color | 260×260    | Buttons only |
| Forerunner 745             | Forerunner | MIP Color | 240×240    | Buttons only |

**Decision:** Start with Tier 1 exclusively. Normalise all coordinates as fractions of
`screenRadius` (half the shorter screen dimension) from the first commit — this makes Tier 2
support a configuration delta, Tier 3 a reduced-feature profile, and eventual square-device
support a parallel layout strategy, not a rewrite of existing components.

---

## 4. Connect IQ Platform Constraints

These are hard constraints, not preferences. Every component design must account for them.

### 4.1 Memory
- Fixed heap per device, typically 256KB–1MB depending on app type (watch face vs device app)
- No dynamic allocation after initialisation in performance-sensitive paths
- Bitmap resources count against heap; avoid per-component bitmap allocations
- **Implication:** components must be allocation-free at draw time. State initialised once,
  reused on every frame.

### 4.2 Graphics API
- `Toybox.Graphics.Dc` (device context) provides: `drawText`, `drawLine`, `drawCircle`,
  `drawArc`, `fillPolygon`, `drawBitmap`, `setColor`, `setPenWidth`
- No path/bezier API
- No hardware-accelerated compositing
- No clipping regions (must clip manually via coordinate math)
- Anti-aliasing: available on AMOLED devices via `Graphics.AntialiasingMode`
- **Implication:** all curved geometry must be approximated with arcs and polygons.
  The library must provide geometric helpers to make this tractable.

### 4.3 Input model
- Touch: `onTap(clickEvent)`, `onSwipe(swipeEvent)` — coordinates in screen pixels
- Buttons: `onKey(keyEvent)` — UP, DOWN, ENTER, BACK, START/STOP
- No hover, no long-press native event (must implement via timer)
- **Implication:** all interactive components must support both touch and button navigation.
  This is a first-class dual-input requirement, not an afterthought.

### 4.4 Update cycle
- Watch faces: `onUpdate()` called by OS — typically 1Hz, up to display refresh rate
- Widgets and apps: event-driven, `requestUpdate()` triggers a redraw
- Always-on display (AOD): restricted palette, max 10% pixel activation on older AMOLED
- **Implication:** components must distinguish between full-colour active mode and AOD mode.
  AOD variants of components are a required deliverable, not optional.

### 4.5 Language
- Monkey C: weakly typed, Java-like syntax, no generics, no closures (lambdas available in
  API 3.2+)
- No inheritance chains deeper than 2–3 levels without heap penalty
- Module system is flat — no package namespacing, prefix convention required
- **Implication:** component API must use composition, not deep inheritance. Interfaces
  (duck typing via `instanceof`) are acceptable.

---

## 5. Design Principles

These principles are non-negotiable and must be referenced in every component PR review.

**P1 — The screen shape is the canvas.**  
Every layout decision starts from the screen's geometry — not a rectangular abstraction imposed
over it. In Phase 1 (round screens), this means all layout originates from the screen centre and
works outward radially. Rectangular subregions are permitted only inside a shape-appropriate
parent container. When square-screen support is added, this principle applies equally: layout
must respect the corners and proportions of that form factor, not assume a circular safe area.

**P2 — Dual-input parity.**  
Every interactive component must be fully operable with buttons alone. Touch is an
enhancement, not a requirement. This is not accessibility — it is a functional baseline,
because gloves, wet hands, and activity profiles routinely disable touch.

**P3 — Allocation-free draw path.**  
No component may allocate memory inside its `draw()` method. All state is initialised in
`initialize()` or `update()`. This is a hard rule enforced by code review, not a guideline.

**P4 — Explicit AOD contract.**  
Every component exposes a boolean `aodMode` flag and a corresponding `drawAod(dc)` method.
The AOD variant must reduce lit pixels to ≤10% of the component's bounding area.

**P5 — Coordinate-system independence.**  
All dimensions are expressed as fractions of `screenRadius` (half the shorter screen dimension)
for round devices, or as fractions of `screenWidth`/`screenHeight` for rectangular devices.
Integer pixel values are computed once at initialisation from these fractions. Switching between
device profiles — including from round to square — is a configuration change at the layout
layer, not a change to component internals.

**P6 — No opinion on data.**  
Components render what they are given. They contain no data-fetching logic, no sensor reads,
no Garmin API calls. Data binding is the caller's responsibility. This enforces the separation
in your Developer's Manifest: components are stateless logic engines; the watch face or widget
is the orchestration layer.

---

## 6. Component Catalogue

Effort is scored in developer-weeks (DW) assuming one developer with Monkey C familiarity.
A Python harness prototype precedes each Monkey C implementation, adding ~30% overhead to
initial components only.

### 6.1 Foundation layer (prerequisite for all components)

| ID   | Component           | Description                                                                            | Effort | Priority |
| ---- | ------------------- | -------------------------------------------------------------------------------------- | ------ | -------- |
| F-01 | `IQKit.Geometry`    | Polar-to-cartesian conversion, arc segment math, polygon approximation helpers         | 0.5 DW | P0       |
| F-02 | `IQKit.Theme`       | Centralised colour palette, font size tokens, stroke weight tokens                     | 0.5 DW | P0       |
| F-03 | `IQKit.Layout`      | `screenRadius` computation, safe-area insets (bezel margin), radial grid helper        | 0.5 DW | P0       |
| F-04 | `IQKit.InputRouter` | Unified tap/swipe/key event dispatcher; normalises button and touch into common events | 1.0 DW | P0       |

**Foundation subtotal: 2.5 DW**

---

### 6.2 Display components

| ID   | Component          | Description                                                                                                                         | Effort | AOD | Priority |
| ---- | ------------------ | ----------------------------------------------------------------------------------------------------------------------------------- | ------ | --- | -------- |
| D-01 | `ArcProgressBar`   | Single-value arc indicator (e.g. Body Battery, HRV). Start/end angle configurable. Animated fill deferred.                          | 0.5 DW | Yes | P0       |
| D-02 | `RadialGauge`      | Multi-zone arc (e.g. HR zones). Configurable zone count, colours, current-value needle.                                             | 1.0 DW | Yes | P1       |
| D-03 | `CentreMetric`     | Large primary value + unit label, vertically centred. The "one number on a watch face" primitive.                                   | 0.5 DW | Yes | P0       |
| D-04 | `ComplicationSlot` | Small circular icon + value pair, positioned at a polar coordinate. Think Apple Watch complications without the brand name.         | 1.0 DW | Yes | P1       |
| D-05 | `StatusRing`       | Thin outer ring divided into configurable segments with discrete states (active/inactive/warning). Useful for weekly goal progress. | 0.5 DW | Yes | P1       |
| D-06 | `MiniSparkline`    | Small arc-bounded line chart for trend data (sleep, stress, HR over time). Fixed point count.                                       | 1.5 DW | No  | P2       |

**Display subtotal: 5.0 DW**

---

### 6.3 Navigation components

This is the highest-value area relative to Garmin's native deficit.

| ID   | Component           | Description                                                                                                                                                                                                      | Effort | AOD | Priority |
| ---- | ------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------ | --- | -------- |
| N-01 | `CircularMenu`      | Radial item layout around the screen centre. Items fan outward from a centre icon. Button navigation cycles focus; touch selects directly. Maximum 8 items.                                                      | 2.0 DW | No  | P0       |
| N-02 | `ArcList`           | Curved vertical list that follows the screen's interior arc rather than a straight rectangle. Reduces content clipping at screen edges. This directly addresses the "square content on a round screen" critique. | 2.5 DW | No  | P0       |
| N-03 | `BottomSheet`       | Semi-circular overlay rising from bottom of screen. Displays secondary options without full navigation depth. Dismissible via swipe-down or BACK button.                                                         | 1.5 DW | No  | P1       |
| N-04 | `PageDots`          | Circular page indicator along the bottom arc. Standard horizontal swipe convention, adapted to circular bounds.                                                                                                  | 0.5 DW | No  | P1       |
| N-05 | `ConfirmDialog`     | Full-screen binary confirmation (confirm/cancel). Two-button radial layout. No more "scroll to Yes, scroll to No" in a rectangle.                                                                                | 1.0 DW | No  | P0       |
| N-06 | `ToastNotification` | Transient arc-shaped message banner appearing at the top third of the screen. Auto-dismisses after configurable duration.                                                                                        | 0.5 DW | No  | P2       |

**Navigation subtotal: 8.0 DW**

---

### 6.4 Reference implementations

Two complete apps using library components only. These are the credibility artefacts — one for
each document.

| ID   | Deliverable                | Description                                                                                                                                                                         | Effort |
| ---- | -------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------ |
| R-01 | Reference Watch Face       | Circular layout. CentreMetric for primary metric, 3× ComplicationSlot at cardinal positions, ArcProgressBar for Body Battery, StatusRing for weekly steps. No rectangular elements. | 2.0 DW |
| R-02 | Reference Dashboard Widget | Single-screen canonical data summary: one weather source, one HR reading, one training status. Demonstrates the "single source of truth" principle. Navigated via CircularMenu.     | 2.5 DW |

**Reference subtotal: 4.5 DW**

---

### 6.5 Tooling

| ID   | Component                   | Description                                                                                                                                                    | Effort |
| ---- | --------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------ |
| T-01 | Python layout harness       | `pygame` or `cairo`-based renderer that draws components using the same coordinate model as Monkey C. Allows rapid visual iteration without the CIQ simulator. | 2.0 DW |
| T-02 | Device configuration matrix | JSON device profile store: screen radius, colour depth, touch capability, API level, AOD constraints. Consumed by both harness and Monkey C layer.             | 0.5 DW |
| T-03 | Contribution guide          | Component authoring checklist (P1–P6 compliance, dual-input test, AOD test, memory benchmark template)                                                         | 0.5 DW |

**Tooling subtotal: 3.0 DW**

---

## 7. Total Scope Estimate

| Layer                     | Effort      |
| ------------------------- | ----------- |
| Foundation                | 2.5 DW      |
| Display components        | 5.0 DW      |
| Navigation components     | 8.0 DW      |
| Reference implementations | 4.5 DW      |
| Tooling                   | 3.0 DW      |
| **Total**                 | **23.0 DW** |

At a realistic solo-developer pace with ramp-up on Monkey C (assumed ~2 weeks), and accounting
for the Python harness reducing Monkey C iteration time:

- **Minimum viable library (P0 components + R-01 + tooling):** ~10 DW → approximately 5 weeks
  solo, or 2–3 weeks with a second contributor.
- **Full Phase 1 scope (all P0 + P1):** ~16 DW → approximately 8 weeks solo.
- **Full spec:** ~23 DW → approximately 12 weeks solo.

These are estimates, not commitments. Monkey C's undocumented heap limits on specific devices
are the primary schedule risk.

---

## 8. Phased Delivery

### Phase 0 — Harness and Foundation (weeks 1–2)
T-01, T-02, F-01 through F-04.  
Exit criterion: Python harness renders a circle, an arc, and a text label at correct scale for
three target device profiles (454×454, 416×416, 390×390).

### Phase 1 — Core components (weeks 3–6)
D-01, D-03, N-01, N-02, N-05.  
Exit criterion: `IQKit.CircularMenu` and `IQKit.ArcList` operate correctly in the CIQ simulator
across at least three round-screen device profiles spanning different lines (e.g. FR970, Fenix 8,
Venu 4), navigable by both touch and buttons.

### Phase 2 — Reference implementations (weeks 7–9)
R-01, R-02, D-04, N-03.  
Exit criterion: Reference watch face installable on physical FR970 hardware.

### Phase 3 — Complete library + documentation (weeks 10–12)
Remaining P1 and P2 components, T-03.  
Exit criterion: Contribution guide complete, library published as open-source with MIT licence.

---

## 9. Risks

| Risk                                                              | Likelihood | Impact | Mitigation                                                                               |
| ----------------------------------------------------------------- | ---------- | ------ | ---------------------------------------------------------------------------------------- |
| Monkey C heap limits prevent component stacking                   | High       | High   | Python harness validates memory model before any Monkey C commit                         |
| CIQ SDK breaking changes between System 7 and 8                   | Medium     | Medium | Target API 6.x minimum; test on both simulator profiles                                  |
| `ArcList` curve approximation is computationally expensive        | Medium     | Medium | Profile in simulator first; fall back to straight-edged list with rounded caps if needed |
| Garmin restricts side-loading in System 8 QMR (already signalled) | Low        | Medium | Library targets published apps via Connect IQ store, not side-loading                    |
| Community adoption is zero, effort is wasted                      | Low        | Low    | Reference implementations + open letters create independent value regardless             |

---

## 10. Open Questions

1. **Python harness renderer:** `pygame` (simpler setup, adequate for layout validation) vs
   `cairo` (more accurate arc and anti-alias rendering, closer to what AMOLED devices produce).
   Decision deferred to author after reviewing Phase 0 requirements.
2. **Square-device layout strategy:** When Phase 2 begins, `IQKit.Layout` will need a
   `ScreenProfile` abstraction that switches between radial (round) and grid (rectangular)
   coordinate systems. The interface contract should be defined — even if not implemented —
   before Phase 1 is complete, to avoid a breaking API change.
3. **Contribution freeze scope:** Phase 0 and Phase 1 are closed to design PRs. The exact
   trigger for opening design contributions (e.g. "after R-01 is installable on hardware")
   should be documented in `CONTRIBUTING.md` before the repository goes public.