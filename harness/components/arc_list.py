"""N-02 | IQKitArcList -- Python harness implementation.

Curved vertical list following the screen's interior arc. Item widths are
constrained by chord length at each y-position, eliminating rectangular
clipping on round screens. Supports scrolling via button nav and touch.

Interface: IQKit Component Interface v1
"""

import math
from dataclasses import dataclass
from typing import Optional

from harness.geometry import polygon_from_arc


@dataclass(frozen=True)
class ArcListItem:
    """Single item in an arc list."""

    primary_text: str
    secondary_text: str = ""


@dataclass(frozen=True)
class ArcListConfig:
    """Configuration injected at initialize() time."""

    visible_items: int = 5
    item_height_fraction: float = 0.12
    inset_fraction: float = 0.08
    show_scrollbar: bool = True


_MAX_VISIBLE = 7


class ArcList:
    """Interactive component: arc-constrained scrollable list."""

    def __init__(self):
        self._cx = 0
        self._cy = 0
        self._radius = 0
        self._item_height = 0
        self._visible_count = 0
        self._inset = 0
        self._slot_y = [0] * _MAX_VISIBLE
        self._slot_x_left = [0] * _MAX_VISIBLE
        self._slot_x_right = [0] * _MAX_VISIBLE
        self._slot_width = [0] * _MAX_VISIBLE
        self._items = []
        self._scroll_offset = 0
        self._focus_index = 0
        self._selected_index = -1
        self._primary_font_size = 0
        self._secondary_font_size = 0
        self._show_scrollbar = True
        self._accent = (0, 200, 80)
        self._text_color = (255, 255, 255)
        self._secondary_color = (180, 180, 180)
        self._dim_color = (60, 60, 60)
        self._background = (0, 0, 0)

    def initialize(self, renderer, theme, config=None):
        """Resolve slot geometry using chord-width computation."""
        if config is None:
            config = ArcListConfig()

        r = renderer.radius
        self._cx, self._cy = renderer.centre
        self._radius = r
        self._item_height = max(20, int(r * config.item_height_fraction))
        self._visible_count = min(config.visible_items, _MAX_VISIBLE)
        self._inset = max(2, int(r * config.inset_fraction))
        self._show_scrollbar = config.show_scrollbar
        self._primary_font_size = max(10, int(r * theme.font_size_small * 1.2))
        self._secondary_font_size = max(8, int(r * theme.font_size_small * 0.85))

        # Compute slot geometry: each slot's width follows the chord at that y.
        total_h = self._visible_count * self._item_height
        start_y = self._cy - total_h // 2

        for i in range(self._visible_count):
            slot_mid_y = start_y + i * self._item_height + self._item_height // 2
            self._slot_y[i] = start_y + i * self._item_height

            dy = slot_mid_y - self._cy
            dy_sq = dy * dy
            r_sq = r * r

            if dy_sq < r_sq:
                half_chord = int(math.sqrt(r_sq - dy_sq)) - self._inset
                half_chord = max(10, half_chord)
            else:
                half_chord = 10

            self._slot_x_left[i] = self._cx - half_chord
            self._slot_x_right[i] = self._cx + half_chord
            self._slot_width[i] = half_chord * 2

        self._accent = theme.accent
        self._text_color = theme.text_color
        self._secondary_color = theme.secondary_color
        self._dim_color = theme.dim_color
        self._background = theme.background
        self._scroll_offset = 0
        self._focus_index = 0
        self._selected_index = -1

    def update(self, items):
        """Set the full item list. Resets scroll and focus."""
        self._items = list(items)
        self._scroll_offset = 0
        self._focus_index = 0
        self._selected_index = -1

    def draw(self, renderer):
        """Render visible items with arc-constrained widths."""
        for slot in range(self._visible_count):
            item_idx = self._scroll_offset + slot
            if item_idx >= len(self._items):
                break

            item = self._items[item_idx]
            focused = item_idx == self._focus_index
            x_left = self._slot_x_left[slot]
            x_right = self._slot_x_right[slot]
            y_top = self._slot_y[slot]

            # Slot background.
            if focused:
                points = [
                    (x_left, y_top),
                    (x_right, y_top),
                    (x_right, y_top + self._item_height),
                    (x_left, y_top + self._item_height),
                ]
                renderer.fill_polygon(points, color=self._dim_color)

            # Primary text.
            text_x = self._cx
            text_y = y_top + self._item_height // 2
            if item.secondary_text:
                text_y = y_top + int(self._item_height * 0.35)

            renderer.draw_text(
                item.primary_text,
                text_x, text_y,
                self._primary_font_size,
                color=self._text_color if focused else self._secondary_color,
            )

            # Secondary text below primary.
            if item.secondary_text:
                sec_y = y_top + int(self._item_height * 0.70)
                renderer.draw_text(
                    item.secondary_text,
                    text_x, sec_y,
                    self._secondary_font_size,
                    color=self._secondary_color,
                )

        # Scrollbar.
        if self._show_scrollbar and len(self._items) > self._visible_count:
            self._draw_scrollbar(renderer)

    def draw_aod(self, renderer):
        """No AOD for navigation components."""
        pass

    def on_input(self, event):
        """Handle input for scroll, focus, and selection."""
        from harness.input_router import InputAction, InputType

        if not self._items:
            return

        if event.action == InputAction.DOWN:
            if self._focus_index < len(self._items) - 1:
                self._focus_index += 1
                if self._focus_index >= self._scroll_offset + self._visible_count:
                    self._scroll_offset += 1
        elif event.action == InputAction.UP:
            if self._focus_index > 0:
                self._focus_index -= 1
                if self._focus_index < self._scroll_offset:
                    self._scroll_offset -= 1
        elif event.action == InputAction.ENTER:
            if event.input_type == InputType.TAP and event.x is not None:
                hit = self._hit_test(event.x, event.y)
                if hit >= 0:
                    self._selected_index = hit
                return
            self._selected_index = self._focus_index
        elif event.action == InputAction.BACK:
            self._selected_index = -1

    def get_selected_index(self):
        return self._selected_index

    def _hit_test(self, tap_x, tap_y):
        """Return absolute item index at tap position, or -1."""
        for slot in range(self._visible_count):
            item_idx = self._scroll_offset + slot
            if item_idx >= len(self._items):
                break
            y_top = self._slot_y[slot]
            if y_top <= tap_y < y_top + self._item_height:
                if self._slot_x_left[slot] <= tap_x <= self._slot_x_right[slot]:
                    return item_idx
        return -1

    def _draw_scrollbar(self, renderer):
        """Draw a thin arc scrollbar on the right side."""
        total = len(self._items)
        if total <= self._visible_count:
            return

        # Scrollbar track arc: right side, from about 340 to 20 degrees.
        track_start = 340.0
        track_end = 380.0
        track_r = self._radius - self._inset // 2

        pen = max(1, int(self._radius * 0.005))
        renderer.set_pen_width(pen)
        renderer.draw_arc(
            self._cx, self._cy, track_r,
            track_start, track_end,
            color=self._dim_color,
        )

        # Scrollbar thumb: proportional segment.
        thumb_fraction = self._visible_count / total
        thumb_offset = self._scroll_offset / total
        sweep = track_end - track_start
        thumb_start = track_start + thumb_offset * sweep
        thumb_end = thumb_start + thumb_fraction * sweep

        thumb_pen = max(2, int(self._radius * 0.012))
        renderer.set_pen_width(thumb_pen)
        renderer.draw_arc(
            self._cx, self._cy, track_r,
            thumb_start, thumb_end,
            color=self._accent,
        )
