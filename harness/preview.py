"""T-01 | IQKit Harness Preview -- entry point.

Renders the Phase 0 exit criterion demonstration: a circle, an arc, and a
text label at correct scale for three target device profiles, displayed
side by side. Also saves PNG snapshots for review.

Usage:
    python -m harness.preview
    python -m harness        (via __main__.py)
"""

import json
import os
import sys

import pygame

from harness.geometry import arc_points
from harness.layout import safe_area_inset, screen_centre, screen_radius
from harness.renderer import HarnessRenderer
from harness.theme import default_theme


# Device IDs for the exit criterion (454, 416, 390).
EXIT_CRITERION_DEVICES = ["fr970", "fenix8_47", "venu3"]

PADDING = 20  # Pixels between device panels.
LABEL_HEIGHT = 30  # Space below each panel for the device label.


def _load_devices(path: str) -> list[dict]:
    with open(path) as f:
        return json.load(f)


def _find_devices(all_devices: list[dict], ids: list[str]) -> list[dict]:
    index = {d["id"]: d for d in all_devices}
    result = []
    for device_id in ids:
        if device_id in index:
            result.append(index[device_id])
        else:
            print(f"Warning: device '{device_id}' not found in devices.json")
    return result


def _render_demo(renderer: HarnessRenderer, theme) -> None:
    """Draw the Phase 0 exit criterion shapes on a single device."""
    cx, cy = renderer.centre
    r = renderer.radius

    renderer.clear(theme.background)

    # 1. Circle at 80% of screen radius.
    circle_r = int(r * 0.80)
    pen = max(1, int(r * theme.stroke_weight_thin))
    renderer.set_pen_width(pen)
    renderer.draw_circle(cx, cy, circle_r, color=theme.secondary_color)

    # 2. Arc from 135 deg to 405 deg (bottom-left to bottom-right, sweeping
    #    through top) at 60% radius. Thick stroke, accent colour.
    arc_r = int(r * 0.60)
    thick_pen = max(2, int(r * theme.stroke_weight_thick))
    renderer.set_pen_width(thick_pen)
    renderer.draw_arc(cx, cy, arc_r, 135, 405, color=theme.accent)

    # 3. Text label centred on screen.
    font_px = max(12, int(r * theme.font_size_medium))
    renderer.draw_text("IQKit", cx, cy, font_px, color=theme.text_color)

    # 4. Resolution annotation below centre.
    small_px = max(10, int(r * theme.font_size_small))
    renderer.draw_text(
        f"{renderer.width}x{renderer.height}",
        cx,
        cy + int(r * 0.18),
        small_px,
        color=theme.secondary_color,
    )

    renderer.apply_clip()


def main() -> None:
    harness_dir = os.path.dirname(os.path.abspath(__file__))
    devices_path = os.path.join(harness_dir, "devices.json")
    snapshots_dir = os.path.join(harness_dir, "snapshots")

    all_devices = _load_devices(devices_path)
    devices = _find_devices(all_devices, EXIT_CRITERION_DEVICES)

    if not devices:
        print("No matching devices found. Check devices.json.")
        sys.exit(1)

    pygame.init()
    pygame.font.init()

    theme = default_theme()
    renderers = []

    for profile in devices:
        r = HarnessRenderer(profile)
        _render_demo(r, theme)
        renderers.append(r)

    # Compute window size: panels side by side with padding.
    total_width = sum(r.width for r in renderers) + PADDING * (len(renderers) + 1)
    max_height = max(r.height for r in renderers)
    total_height = max_height + PADDING * 2 + LABEL_HEIGHT

    screen = pygame.display.set_mode((total_width, total_height))
    pygame.display.set_caption("IQKit Harness -- Phase 0 Exit Criterion")
    screen.fill((30, 30, 30))

    # Blit each device panel.
    x_offset = PADDING
    for r in renderers:
        y_offset = PADDING + (max_height - r.height) // 2
        screen.blit(r.surface, (x_offset, y_offset))

        # Device label below.
        label = r.get_label_surface()
        label_x = x_offset + (r.width - label.get_width()) // 2
        label_y = PADDING + max_height + 6
        screen.blit(label, (label_x, label_y))

        x_offset += r.width + PADDING

    pygame.display.flip()

    # Save snapshots.
    os.makedirs(snapshots_dir, exist_ok=True)
    for r in renderers:
        path = os.path.join(snapshots_dir, f"{r._profile['id']}.png")
        pygame.image.save(r.surface, path)
    composite_path = os.path.join(snapshots_dir, "phase0_exit_criterion.png")
    pygame.image.save(screen, composite_path)
    print(f"Snapshots saved to {snapshots_dir}/")

    # Event loop -- close on quit or Escape.
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
