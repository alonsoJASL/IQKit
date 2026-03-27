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

**Before opening a PR, verify:**

- [ ] No heap allocation inside `draw()` or any method called by `draw()`
- [ ] All dimensions computed as fractions of `screenRadius` (or equivalent), resolved to
      integers in `initialize()`
- [ ] Component imports no data APIs (`Toybox.Activity`, `Toybox.Weather`, `Toybox.SensorHistory`,
      etc.)
- [ ] `drawAod(dc)` implemented and producing ≤10% lit pixels if component emits light
- [ ] Dual-input: component is fully operable via UP/DOWN/ENTER/BACK without touch
- [ ] All public symbols prefixed with `IQKit`
- [ ] Internal symbols prefixed with `_`
- [ ] Spec component ID present in file header comment (e.g. `// D-01 ArcProgressBar`)
- [ ] Heap delta documented in the component's docstring
- [ ] Python harness rendering reviewed before Monkey C implementation was started

---

## Licence

By contributing to IQKit you agree that your contributions are licensed under the MIT licence.
See `LICENSE`.