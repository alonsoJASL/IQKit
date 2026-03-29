"""T-01 | IQKit Harness Preview -- entry point.

Renders Phase 0 exit criterion and all Phase 1 components at correct scale
for three target device profiles, displayed side by side. Saves PNG snapshots.

Usage:
    python -m harness.preview          # composite grid (all scenes)
    python -m harness                  (via __main__.py)
"""

import json
import os
import sys

import pygame

from harness.geometry import arc_points
from harness.layout import safe_area_inset, screen_centre, screen_radius
from harness.renderer import HarnessRenderer
from harness.theme import default_theme
from harness.components import (
    ArcList,
    ArcListConfig,
    ArcListItem,
    ArcProgressBar,
    ArcProgressBarConfig,
    CentreMetric,
    CircularMenu,
    CircularMenuConfig,
    CircularMenuItem,
    ConfirmDialog,
    ConfirmDialogConfig,
)


PREVIEW_DEVICES = ["fr970", "fenix8_47", "venu3"]

PADDING = 16
LABEL_HEIGHT = 26
ROW_GAP = 8


def _load_devices(path):
    with open(path) as f:
        return json.load(f)


def _find_devices(all_devices, ids):
    index = {d["id"]: d for d in all_devices}
    result = []
    for device_id in ids:
        if device_id in index:
            result.append(index[device_id])
        else:
            print(f"Warning: device '{device_id}' not found in devices.json")
    return result


# ---------------------------------------------------------------------------
# Scene functions: each creates a component, initializes, updates, draws.
# ---------------------------------------------------------------------------

def scene_phase0(renderer, theme, aod=False):
    """Phase 0 exit criterion shapes."""
    cx, cy = renderer.centre
    r = renderer.radius
    renderer.clear(theme.background)

    circle_r = int(r * 0.80)
    pen = max(1, int(r * theme.stroke_weight_thin))
    renderer.set_pen_width(pen)
    renderer.draw_circle(cx, cy, circle_r, color=theme.secondary_color)

    arc_r = int(r * 0.60)
    thick_pen = max(2, int(r * theme.stroke_weight_thick))
    renderer.set_pen_width(thick_pen)
    renderer.draw_arc(cx, cy, arc_r, 135, 405, color=theme.accent)

    font_px = max(12, int(r * theme.font_size_medium))
    renderer.draw_text("IQKit", cx, cy, font_px, color=theme.text_color)

    small_px = max(10, int(r * theme.font_size_small))
    renderer.draw_text(
        f"{renderer.width}x{renderer.height}",
        cx, cy + int(r * 0.18), small_px, color=theme.secondary_color,
    )
    renderer.apply_clip()


def scene_centre_metric(renderer, theme, aod=False):
    """D-03 CentreMetric."""
    renderer.clear(theme.background)
    cm = CentreMetric()
    cm.initialize(renderer, theme)
    cm.update("72", "bpm")
    if aod:
        cm.draw_aod(renderer)
    else:
        cm.draw(renderer)
    renderer.apply_clip()


def scene_arc_progress(renderer, theme, aod=False):
    """D-01 ArcProgressBar."""
    renderer.clear(theme.background)
    apb = ArcProgressBar()
    apb.initialize(renderer, theme)
    apb.update(0.72)
    if aod:
        apb.draw_aod(renderer)
    else:
        apb.draw(renderer)
    renderer.apply_clip()


def scene_confirm_dialog(renderer, theme, aod=False):
    """N-05 ConfirmDialog."""
    renderer.clear(theme.background)
    cd = ConfirmDialog()
    cd.initialize(renderer, theme)
    cd.update("Delete activity?")
    cd.draw(renderer)
    renderer.apply_clip()


def scene_circular_menu(renderer, theme, aod=False):
    """N-01 CircularMenu."""
    renderer.clear(theme.background)
    items = tuple(
        CircularMenuItem(label=lbl)
        for lbl in ["Run", "Bike", "Swim", "Hike", "Gym"]
    )
    config = CircularMenuConfig(items=items, title="Start")
    cm = CircularMenu()
    cm.initialize(renderer, theme, config)
    cm.draw(renderer)
    renderer.apply_clip()


def scene_arc_list(renderer, theme, aod=False):
    """N-02 ArcList."""
    renderer.clear(theme.background)
    items = [
        ArcListItem("Morning Run", "5.2 km"),
        ArcListItem("Afternoon Bike", "22.1 km"),
        ArcListItem("Evening Walk", "1.8 km"),
        ArcListItem("Swim Session", "1500 m"),
        ArcListItem("Strength Training", "45 min"),
        ArcListItem("Yoga", "30 min"),
        ArcListItem("Trail Run", "8.4 km"),
    ]
    al = ArcList()
    al.initialize(renderer, theme)
    al.update(items)
    al.draw(renderer)
    renderer.apply_clip()


# All scenes in display order: (name, function, has_aod).
SCENES = [
    ("Phase 0", scene_phase0, False),
    ("D-03 CentreMetric", scene_centre_metric, True),
    ("D-03 AOD", scene_centre_metric, True),
    ("D-01 ArcProgress", scene_arc_progress, True),
    ("D-01 AOD", scene_arc_progress, True),
    ("N-05 ConfirmDialog", scene_confirm_dialog, False),
    ("N-01 CircularMenu", scene_circular_menu, False),
    ("N-02 ArcList", scene_arc_list, False),
]

# Which scene indices render in AOD mode.
_AOD_ROWS = {2, 4}


def main():
    harness_dir = os.path.dirname(os.path.abspath(__file__))
    devices_path = os.path.join(harness_dir, "devices.json")
    snapshots_dir = os.path.join(harness_dir, "snapshots")

    all_devices = _load_devices(devices_path)
    devices = _find_devices(all_devices, PREVIEW_DEVICES)

    if not devices:
        print("No matching devices found. Check devices.json.")
        sys.exit(1)

    pygame.init()
    pygame.font.init()

    theme = default_theme()

    # Render all scenes for all devices into a grid.
    # Grid layout: rows = scenes, columns = devices.
    num_rows = len(SCENES)
    num_cols = len(devices)

    # Render each cell.
    cells = []  # List of (row, col, renderer)
    for row_idx, (scene_name, scene_fn, has_aod) in enumerate(SCENES):
        is_aod = row_idx in _AOD_ROWS
        for col_idx, profile in enumerate(devices):
            r = HarnessRenderer(profile)
            scene_fn(r, theme, aod=is_aod)
            cells.append((row_idx, col_idx, r))

    # Compute grid dimensions.
    col_widths = [devices[c]["resolution"][0] for c in range(num_cols)]
    row_heights = [devices[0]["resolution"][1]] * num_rows  # All same height per row.

    # Actually compute max height per row from the tallest device.
    max_device_height = max(d["resolution"][1] for d in devices)
    total_width = (
        PADDING
        + sum(col_widths)
        + PADDING * num_cols
        + 120  # Room for row labels on the left.
    )
    total_height = (
        PADDING
        + LABEL_HEIGHT
        + (max_device_height + ROW_GAP) * num_rows
        + PADDING
    )

    screen = pygame.display.set_mode((total_width, total_height))
    pygame.display.set_caption("IQKit Harness -- Phase 1")
    screen.fill((30, 30, 30))

    label_font = pygame.font.SysFont("monospace", 12)
    row_label_font = pygame.font.SysFont("monospace", 11)

    # Column headers (device names).
    x_offset = PADDING + 120
    for col_idx, profile in enumerate(devices):
        lbl = label_font.render(
            f"{profile['name']} ({profile['resolution'][0]})",
            True, (200, 200, 200),
        )
        lbl_x = x_offset + (col_widths[col_idx] - lbl.get_width()) // 2
        screen.blit(lbl, (lbl_x, PADDING))
        x_offset += col_widths[col_idx] + PADDING

    # Render grid cells.
    for row_idx, col_idx, renderer in cells:
        x = PADDING + 120
        for c in range(col_idx):
            x += col_widths[c] + PADDING

        y = PADDING + LABEL_HEIGHT + row_idx * (max_device_height + ROW_GAP)

        # Centre vertically if device is shorter.
        y_centre = y + (max_device_height - renderer.height) // 2
        screen.blit(renderer.surface, (x, y_centre))

    # Row labels.
    for row_idx, (scene_name, _, _) in enumerate(SCENES):
        y = PADDING + LABEL_HEIGHT + row_idx * (max_device_height + ROW_GAP)
        y_mid = y + max_device_height // 2
        lbl = row_label_font.render(scene_name, True, (180, 180, 180))
        screen.blit(lbl, (PADDING, y_mid - lbl.get_height() // 2))

    pygame.display.flip()

    # Save snapshots.
    os.makedirs(snapshots_dir, exist_ok=True)

    # Per-component snapshots (fr970 only = first column).
    snapshot_names = {
        0: "phase0_exit_criterion",
        1: "d03_centre_metric",
        2: "d03_centre_metric_aod",
        3: "d01_arc_progress_bar",
        4: "d01_arc_progress_bar_aod",
        5: "n05_confirm_dialog",
        6: "n01_circular_menu",
        7: "n02_arc_list",
    }
    for row_idx, col_idx, renderer in cells:
        if col_idx == 0 and row_idx in snapshot_names:
            path = os.path.join(
                snapshots_dir, f"{snapshot_names[row_idx]}.png",
            )
            pygame.image.save(renderer.surface, path)

    composite_path = os.path.join(snapshots_dir, "phase1_composite.png")
    pygame.image.save(screen, composite_path)
    print(f"Snapshots saved to {snapshots_dir}/")

    # Event loop.
    running = True
    while running:
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                running = False
            elif event.type == pygame.KEYDOWN and event.key == pygame.K_ESCAPE:
                running = False

    pygame.quit()


if __name__ == "__main__":
    main()
