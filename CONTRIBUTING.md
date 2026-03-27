# Contributing to IQKit

Thank you for your interest. Before you open a PR or an issue, read this document in full.
IQKit is in active early development and the contribution model reflects that.

---

## Phase status

| Phase                               | Status      | Design PRs | Bug reports | Feature requests |
| ----------------------------------- | ----------- | ---------- | ----------- | ---------------- |
| Phase 0 — Harness and Foundation    | In progress | Closed     | Open        | Closed           |
| Phase 1 — Core components           | Not started | Closed     | Open        | Closed           |
| Phase 2 — Reference implementations | Not started | Closed     | Open        | Closed           |
| Phase 3 — Full library              | Not started | Open       | Open        | Open             |

**What "Closed" means:** PRs of that type will be closed without review. This is not a
judgment on their quality. It is a constraint on the maintainer's bandwidth during the period
when architectural decisions are being made and tested. Opening design PRs against a locked
foundation wastes your time and the maintainer's.

The phase status above will be updated in this file when phases change. Watch the repository
if you want to be notified.

---

## What you can do right now

**File a bug against the spec.** If a decision in `DESIGN.md` is internally inconsistent,
contradicts a stated Monkey C platform constraint, or references an API that does not exist,
open an issue tagged `spec-bug`. These are welcome at any phase.

**File a bug against the harness or a component.** If implemented code produces incorrect
output, crashes the simulator, or violates a `DESIGN.md` rule, open an issue tagged `bug`
with: the device profile, the CIQ SDK version, and a minimal reproduction.

**Test on hardware.** If you have a round-screen Garmin device from the target matrix and
are willing to test reference implementations on physical hardware, open an issue tagged
`hardware-test` and list your device. This is the most valuable contribution you can make
during Phase 1 and Phase 2.

---

## What you cannot do right now

- Propose new components
- Propose changes to the coordinate system, memory model, or data binding contract
- Propose renaming or restructuring the module layout
- Open PRs that add components not in the `spec.md` catalogue
- Open PRs that modify `DESIGN.md`

If you have a strong opinion on any of these, write it down and open an issue tagged
`design-question`. It will be labelled `phase-3` and addressed when the contribution
process opens. Your issue will not be closed — it will wait.

---

## Code standards

All contributions to Monkey C source must comply with the rules in `DESIGN.md`. The checklist
below is not exhaustive — `DESIGN.md` is the authority. This is a quick reference for reviewers.

**On adding utility functions to the Foundation layer:**

A function is not added to `IQKit.Geometry`, `IQKit.Layout`, or any other Tier 1 module
because it seems useful or because one component needs it. It is added when three separate
components have independently implemented the same logic. Before that threshold, the logic
lives inside the component that needs it as a private `_` method. If you are proposing a
new Foundation utility, your PR must name all three components that require it and show the
duplicated code in each.

This is not bureaucracy. A premature Foundation abstraction that turns out to be wrong must
be changed across every component that depends on it. An over-hasty abstraction is more
expensive than duplication.

**Before opening a PR, verify:**

- [ ] No heap allocation inside `draw()` or any method called by `draw()`
- [ ] All dimensions computed as fractions of `screenRadius` (or equivalent), resolved to
      integers in `initialize()`
- [ ] Component imports no data APIs (`Toybox.Activity`, `Toybox.Weather`, `Toybox.SensorHistory`,
      etc.)
- [ ] `drawAod(dc)` implemented; produces ≤10% lit pixels if component emits light; no-op if
      display-only — but the method must exist regardless
- [ ] Dual-input: component is fully operable via UP/DOWN/ENTER/BACK without touch
- [ ] All public symbols prefixed with `IQKit`
- [ ] Internal symbols prefixed with `_`
- [ ] Spec component ID, interface version, and heap delta present in file header comment
- [ ] `update()` accepts a typed data class, not raw positional arguments, if more than two
      values are required
- [ ] `initialize()` uses a Builder or config data class if more than three configuration
      values are required; Builder is in the same file as the component
- [ ] Theme tokens are injected via `initialize()` — component does not call `IQKit.Theme`
      directly
- [ ] Python harness rendering reviewed and accepted before this Monkey C implementation
      was started; harness covers full parameter range and AOD mode
- [ ] New Foundation utility functions (Tier 1) cite the three independent use cases that
      justify their existence

---

## Licence

By contributing to IQKit you agree that your contributions are licensed under the MIT licence.
See `LICENSE`.