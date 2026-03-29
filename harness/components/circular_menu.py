"""N-01 | IQKitCircularMenu -- Python harness implementation.

Radial item layout around screen centre. Items fan outward at equal angular
intervals. Button nav cycles focus; touch selects directly. Max 8 items.

Interface: IQKit Component Interface v1
"""

import math
from dataclasses import dataclass, field

from harness.layout import radial_position


@dataclass(frozen=True)
class CircularMenuItem:
    """Single item in a circular menu."""

    label: str
    icon: str = ""


@dataclass(frozen=True)
class CircularMenuConfig:
    """Configuration injected at initialize() time."""

    items: tuple = ()
    item_radius_fraction: float = 0.12
    ring_radius_fraction: float = 0.52
    start_angle: float = 270.0
    title: str = ""


_MAX_ITEMS = 8


class CircularMenu:
    """Interactive component: radial item selector."""

    def __init__(self):
        self._cx = 0
        self._cy = 0
        self._item_x = [0] * _MAX_ITEMS
        self._item_y = [0] * _MAX_ITEMS
        self._labels = [""] * _MAX_ITEMS
        self._item_count = 0
        self._item_radius = 0
        self._title = ""
        self._title_font_size = 0
        self._label_font_size = 0
        self._focus_index = 0
        self._selected_index = -1
        self._accent = (0, 200, 80)
        self._text_color = (255, 255, 255)
        self._secondary_color = (180, 180, 180)
        self._dim_color = (60, 60, 60)
        self._background = (0, 0, 0)
        self._centre_radius = 0

    def initialize(self, renderer, theme, config=None):
        """Resolve all dimensions and compute item positions."""
        if config is None:
            config = CircularMenuConfig()

        r = renderer.radius
        self._cx, self._cy = renderer.centre
        self._item_radius = int(r * config.item_radius_fraction)
        ring_r = int(r * config.ring_radius_fraction)
        self._title = config.title
        self._title_font_size = max(10, int(r * theme.font_size_small))
        self._label_font_size = max(10, int(r * theme.font_size_small))
        self._centre_radius = int(r * 0.18)

        items = config.items[:_MAX_ITEMS]
        self._item_count = len(items)

        if self._item_count > 0:
            angle_step = 360.0 / self._item_count
            for i in range(self._item_count):
                angle = config.start_angle + i * angle_step
                ix, iy = radial_position(self._cx, self._cy, ring_r, angle)
                self._item_x[i] = ix
                self._item_y[i] = iy
                self._labels[i] = items[i].label

        self._accent = theme.accent
        self._text_color = theme.text_color
        self._secondary_color = theme.secondary_color
        self._dim_color = theme.dim_color
        self._background = theme.background
        self._focus_index = 0
        self._selected_index = -1

    def update(self, items):
        """Update item labels. Item count must match initialize count."""
        count = min(len(items), self._item_count)
        for i in range(count):
            self._labels[i] = items[i].label

    def draw(self, renderer):
        """Render centre title and radial item circles."""
        # Centre circle with title.
        renderer.fill_circle(
            self._cx, self._cy, self._centre_radius, color=self._dim_color,
        )
        if self._title:
            renderer.draw_text(
                self._title,
                self._cx, self._cy,
                self._title_font_size,
                color=self._text_color,
            )

        # Item circles.
        for i in range(self._item_count):
            focused = i == self._focus_index
            ix, iy = self._item_x[i], self._item_y[i]

            # Filled circle background.
            renderer.fill_circle(
                ix, iy, self._item_radius, color=self._background,
            )

            # Ring.
            pen = max(2, int(renderer.radius * 0.015))
            if focused:
                pen = max(3, int(renderer.radius * 0.025))
            renderer.set_pen_width(pen)
            ring_color = self._accent if focused else self._secondary_color
            renderer.draw_circle(ix, iy, self._item_radius, color=ring_color)

            # Label.
            text_color = self._text_color if focused else self._secondary_color
            renderer.draw_text(
                self._labels[i], ix, iy,
                self._label_font_size,
                color=text_color,
            )

    def draw_aod(self, renderer):
        """No AOD for navigation components."""
        pass

    def on_input(self, event):
        """Handle input for focus cycling and selection."""
        from harness.input_router import InputAction, InputType

        if self._item_count == 0:
            return

        if event.action == InputAction.DOWN:
            self._focus_index = (self._focus_index + 1) % self._item_count
        elif event.action == InputAction.UP:
            self._focus_index = (self._focus_index - 1) % self._item_count
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
        """Return item index at tap position, or -1."""
        r_sq = self._item_radius * self._item_radius
        for i in range(self._item_count):
            dx = tap_x - self._item_x[i]
            dy = tap_y - self._item_y[i]
            if dx * dx + dy * dy <= r_sq:
                return i
        return -1
