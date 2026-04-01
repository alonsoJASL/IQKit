# IQKit Phase 1 Tutorial

How to use and test every Phase 1 component in the Python harness.


## Setup

```bash
conda activate iqkit
pip install -e harness/
```

Run the full preview grid (all components, 3 device profiles):

```bash
python -m harness.preview
```

This opens a pygame window and saves per-component PNGs to `harness/snapshots/`.


## The 4-Method Contract

Every IQKit component follows the same lifecycle:

```
initialize(renderer, theme, ...)   # resolve dimensions, store colours
update(...)                        # set data (never called in draw path)
draw(renderer)                     # render at full brightness
draw_aod(renderer)                 # render AOD variant (display components only)
```

Interactive components also implement `on_input(event)`.


## Boilerplate: Rendering a Single Component

Every script below starts from this skeleton. It loads a device profile,
creates a renderer, and runs a pygame event loop.

```python
"""Standalone test for a single IQKit component."""

import json
import os

import pygame

from harness.renderer import HarnessRenderer
from harness.theme import default_theme
from harness.input_router import InputRouter

def load_device(device_id="fr970"):
    devices_path = os.path.join(
        os.path.dirname(__file__), "harness", "devices.json"
    )
    with open(devices_path) as f:
        devices = json.load(f)
    return next(d for d in devices if d["id"] == device_id)


def run(component, interactive=False):
    """Generic event loop. Redraws on every input event."""
    pygame.init()
    profile = load_device("fr970")
    renderer = HarnessRenderer(profile)
    theme = default_theme()

    screen = pygame.display.set_mode((renderer.width, renderer.height))
    pygame.display.set_caption("IQKit Test")

    router = InputRouter()
    if interactive:
        router.add_target(component)

    def redraw():
        renderer.clear(theme.background)
        component.draw(renderer)
        renderer.apply_clip()
        screen.blit(renderer.surface, (0, 0))
        pygame.display.flip()

    component.initialize(renderer, theme)  # <-- override per component
    redraw()

    running = True
    while running:
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                running = False
            elif event.type == pygame.KEYDOWN and event.key == pygame.K_ESCAPE:
                running = False
            else:
                result = router.process_pygame_event(event)
                if result is not None:
                    redraw()

    pygame.quit()
```

Save this as `test_component.py` at the repo root. The examples below show
what to add before the `run(...)` call for each component.


## 1. CentreMetric (D-03) -- Display

```python
from harness.components import CentreMetric

cm = CentreMetric()

# Override the generic initialize/redraw:
def setup(renderer, theme):
    cm.initialize(renderer, theme)
    cm.update("72", "bpm")

# In the event loop, toggle AOD with the space bar:
# if event.key == pygame.K_SPACE: use cm.draw_aod(renderer) instead
```

Full standalone test:

```python
import json, os, pygame
from harness.renderer import HarnessRenderer
from harness.theme import default_theme
from harness.components import CentreMetric

pygame.init()
with open("harness/devices.json") as f:
    profile = next(d for d in json.load(f) if d["id"] == "fr970")

renderer = HarnessRenderer(profile)
theme = default_theme()
screen = pygame.display.set_mode((renderer.width, renderer.height))

cm = CentreMetric()
cm.initialize(renderer, theme)
cm.update("72", "bpm")

aod = False
running = True
while running:
    renderer.clear(theme.background)
    cm.draw_aod(renderer) if aod else cm.draw(renderer)
    renderer.apply_clip()
    screen.blit(renderer.surface, (0, 0))
    pygame.display.flip()

    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            running = False
        elif event.type == pygame.KEYDOWN:
            if event.key == pygame.K_ESCAPE:
                running = False
            elif event.key == pygame.K_SPACE:
                aod = not aod
            # Try different values:
            elif event.key == pygame.K_1:
                cm.update("142", "bpm")
            elif event.key == pygame.K_2:
                cm.update("85", "%")
            elif event.key == pygame.K_3:
                cm.update("--", "")

pygame.quit()
```

**Keys:** Space = toggle AOD, 1/2/3 = change displayed value, Escape = quit.


## 2. ArcProgressBar (D-01) -- Display

```python
import json, os, pygame
from harness.renderer import HarnessRenderer
from harness.theme import default_theme
from harness.components import ArcProgressBar, ArcProgressBarConfig

pygame.init()
with open("harness/devices.json") as f:
    profile = next(d for d in json.load(f) if d["id"] == "fr970")

renderer = HarnessRenderer(profile)
theme = default_theme()
screen = pygame.display.set_mode((renderer.width, renderer.height))

apb = ArcProgressBar()

# Default config: 135-405 deg sweep, 70% radius, 8% thickness.
# Customise like this:
# config = ArcProgressBarConfig(start_angle=180.0, end_angle=360.0)
# apb.initialize(renderer, theme, config)

apb.initialize(renderer, theme)
progress = 0.72
apb.update(progress)

aod = False
running = True
while running:
    renderer.clear(theme.background)
    apb.draw_aod(renderer) if aod else apb.draw(renderer)
    renderer.apply_clip()
    screen.blit(renderer.surface, (0, 0))
    pygame.display.flip()

    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            running = False
        elif event.type == pygame.KEYDOWN:
            if event.key == pygame.K_ESCAPE:
                running = False
            elif event.key == pygame.K_SPACE:
                aod = not aod
            elif event.key == pygame.K_UP:
                progress = min(1.0, progress + 0.05)
                apb.update(progress)
            elif event.key == pygame.K_DOWN:
                progress = max(0.0, progress - 0.05)
                apb.update(progress)

pygame.quit()
```

**Keys:** Up/Down = adjust progress, Space = toggle AOD.


## 3. ConfirmDialog (N-05) -- Interactive

```python
import json, os, pygame
from harness.renderer import HarnessRenderer
from harness.theme import default_theme
from harness.input_router import InputRouter
from harness.components import ConfirmDialog, ConfirmDialogConfig, RESULT_CONFIRM, RESULT_CANCEL

pygame.init()
with open("harness/devices.json") as f:
    profile = next(d for d in json.load(f) if d["id"] == "fr970")

renderer = HarnessRenderer(profile)
theme = default_theme()
screen = pygame.display.set_mode((renderer.width, renderer.height))

config = ConfirmDialogConfig(
    prompt_text="Delete activity?",
    confirm_label="Yes",
    cancel_label="No",
)
dialog = ConfirmDialog()
dialog.initialize(renderer, theme, config)

router = InputRouter()
router.add_target(dialog)

running = True
while running:
    renderer.clear(theme.background)
    dialog.draw(renderer)
    renderer.apply_clip()
    screen.blit(renderer.surface, (0, 0))
    pygame.display.flip()

    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            running = False
        elif event.type == pygame.KEYDOWN and event.key == pygame.K_ESCAPE:
            running = False
        else:
            router.process_pygame_event(event)

        result = dialog.get_result()
        if result == RESULT_CONFIRM:
            print("User confirmed!")
            running = False
        elif result == RESULT_CANCEL:
            print("User cancelled.")
            running = False

pygame.quit()
```

**Keys:** Up/Down = toggle focus between Yes/No, Enter = select,
Escape = cancel. Click a button to tap-select.


## 4. CircularMenu (N-01) -- Interactive

```python
import json, os, pygame
from harness.renderer import HarnessRenderer
from harness.theme import default_theme
from harness.input_router import InputRouter
from harness.components import CircularMenu, CircularMenuConfig, CircularMenuItem

pygame.init()
with open("harness/devices.json") as f:
    profile = next(d for d in json.load(f) if d["id"] == "fr970")

renderer = HarnessRenderer(profile)
theme = default_theme()
screen = pygame.display.set_mode((renderer.width, renderer.height))

items = tuple(
    CircularMenuItem(label=lbl)
    for lbl in ["Run", "Bike", "Swim", "Hike", "Gym"]
)
config = CircularMenuConfig(items=items, title="Start")

menu = CircularMenu()
menu.initialize(renderer, theme, config)

router = InputRouter()
router.add_target(menu)

running = True
while running:
    renderer.clear(theme.background)
    menu.draw(renderer)
    renderer.apply_clip()
    screen.blit(renderer.surface, (0, 0))
    pygame.display.flip()

    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            running = False
        elif event.type == pygame.KEYDOWN and event.key == pygame.K_ESCAPE:
            running = False
        else:
            router.process_pygame_event(event)

        selected = menu.get_selected_index()
        if selected >= 0:
            print(f"Selected: {items[selected].label}")
            running = False

pygame.quit()
```

**Keys:** Up/Down = cycle focus around the ring, Enter = select,
click an item circle to tap-select. Try changing the item count
(2, 3, 8) to see the radial layout adapt.


## 5. ArcList (N-02) -- Interactive

```python
import json, os, pygame
from harness.renderer import HarnessRenderer
from harness.theme import default_theme
from harness.input_router import InputRouter
from harness.components import ArcList, ArcListConfig, ArcListItem

pygame.init()
with open("harness/devices.json") as f:
    profile = next(d for d in json.load(f) if d["id"] == "fr970")

renderer = HarnessRenderer(profile)
theme = default_theme()
screen = pygame.display.set_mode((renderer.width, renderer.height))

items = [
    ArcListItem("Morning Run", "5.2 km"),
    ArcListItem("Afternoon Bike", "22.1 km"),
    ArcListItem("Evening Walk", "1.8 km"),
    ArcListItem("Swim Session", "1500 m"),
    ArcListItem("Strength Training", "45 min"),
    ArcListItem("Yoga", "30 min"),
    ArcListItem("Trail Run", "8.4 km"),
    ArcListItem("Indoor Cycling", "18.3 km"),
    ArcListItem("Pilates", "25 min"),
    ArcListItem("Open Water Swim", "2.0 km"),
]

arc_list = ArcList()
arc_list.initialize(renderer, theme)
arc_list.update(items)

router = InputRouter()
router.add_target(arc_list)

running = True
while running:
    renderer.clear(theme.background)
    arc_list.draw(renderer)
    renderer.apply_clip()
    screen.blit(renderer.surface, (0, 0))
    pygame.display.flip()

    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            running = False
        elif event.type == pygame.KEYDOWN and event.key == pygame.K_ESCAPE:
            running = False
        else:
            router.process_pygame_event(event)

        selected = arc_list.get_selected_index()
        if selected >= 0:
            print(f"Selected: {items[selected].primary_text}")
            running = False

pygame.quit()
```

**Keys:** Up/Down = scroll and move focus, Enter = select, click an item
to tap-select. Notice how item widths narrow at the top and bottom of the
screen -- that is the chord-width constraint in action.


## Testing Across Device Profiles

Replace `"fr970"` with any device ID from `harness/devices.json`:

| ID                  | Resolution | Notes               |
|---------------------|------------|----------------------|
| `fr970`             | 454x454    | Canonical, AMOLED    |
| `fenix8_47`         | 416x416    | Slightly smaller     |
| `venu3`             | 390x390    | Tier 2 AMOLED        |
| `fr265s`            | 360x360    | Smallest AMOLED      |
| `instinct3_amoled`  | 390x390    | No touch (buttons only) |
| `fenix8_solar`      | 280x280    | MIP, no touch, 8-bit |

The `instinct3_amoled` profile is useful for testing button-only navigation
since `touch: false` means mouse clicks in the harness still work but
represent a scenario where only keyboard/button input would exist on device.


## Custom Themes

Override any token from the default theme:

```python
from harness.theme import IQKitThemeTokens

night_theme = IQKitThemeTokens(
    primary_color=(200, 200, 255),
    secondary_color=(120, 120, 160),
    background=(0, 0, 0),
    text_color=(200, 200, 255),
    accent=(80, 120, 255),
    warning=(255, 60, 60),
    dim_color=(40, 40, 60),
    font_size_large=0.14,
    font_size_medium=0.09,
    font_size_small=0.06,
    stroke_weight_thick=0.03,
    stroke_weight_thin=0.01,
)
# Pass night_theme instead of default_theme() to initialize()
```


## Composing Components

Components can share a renderer. Draw them in order (back to front):

```python
from harness.components import ArcProgressBar, CentreMetric

apb = ArcProgressBar()
apb.initialize(renderer, theme)
apb.update(0.72)

cm = CentreMetric()
cm.initialize(renderer, theme)
cm.update("72", "%")

# Draw loop:
renderer.clear(theme.background)
apb.draw(renderer)     # arc behind
cm.draw(renderer)      # text on top
renderer.apply_clip()  # MUST be last
```

This is the pattern a watch face would use: ArcProgressBar as the
background ring with CentreMetric showing the numeric value in the centre.


## Gotchas

- `apply_clip()` must be the last drawing call. It replaces the internal
  surface with a circle-masked version. Anything drawn after is lost.
- Components are stateless between `initialize` calls. If you resize the
  window or switch device profiles, call `initialize` again.
- The harness uses `pygame.font.SysFont("monospace")` which looks nothing
  like Garmin fonts. Layout and sizing are correct; glyph shapes are not.
- `update()` is where data changes happen. Never mutate component state
  directly -- always go through `update()` so the component can recompute
  any derived geometry (like the fill polygon in ArcProgressBar).

## Notice
Once downloaded, the SDK will be in: 
+ Linux: `$HOME/.Garmin/ConnectIQ/` 
+ MacOS: `$HOME/Library/Application Support/Garmin/ConnectIQ`