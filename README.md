# IQKit

A Monkey C UI component library for Garmin Connect IQ round-screen devices.

IQKit provides reusable, allocation-free rendering components designed for
circular AMOLED and MIP displays. All layout uses polar coordinates and
fractional screen dimensions -- no hard-coded pixel values.

**Status:** Phase 0 -- Harness and Foundation (in progress)

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

## License

MIT. See [LICENSE](LICENSE).
