"""N-05 | IQKitConfirmDialog -- Python harness implementation.

Full-screen binary confirm/cancel dialog. Two circular buttons at radial
positions. Button nav toggles focus; touch selects directly.

Interface: IQKit Component Interface v1
"""

import math
from dataclasses import dataclass
from typing import Callable, Optional

from harness.layout import radial_position


RESULT_PENDING = -1
RESULT_CONFIRM = 0
RESULT_CANCEL = 1


@dataclass(frozen=True)
class ConfirmDialogConfig:
    """Configuration injected at initialize() time."""

    prompt_text: str = "Confirm?"
    confirm_label: str = "Yes"
    cancel_label: str = "No"
    confirm_angle: float = 45.0
    cancel_angle: float = 135.0
    button_radius_fraction: float = 0.18
    button_distance_fraction: float = 0.42


class ConfirmDialog:
    """Interactive component: binary confirm/cancel selection."""

    def __init__(self):
        self._cx = 0
        self._cy = 0
        self._prompt_font_size = 0
        self._label_font_size = 0
        self._button_radius = 0
        self._confirm_x = 0
        self._confirm_y = 0
        self._cancel_x = 0
        self._cancel_y = 0
        self._prompt_text = "Confirm?"
        self._confirm_label = "Yes"
        self._cancel_label = "No"
        self._focus_index = 0
        self._result = RESULT_PENDING
        self._accent = (0, 200, 80)
        self._warning = (255, 80, 40)
        self._text_color = (255, 255, 255)
        self._secondary_color = (180, 180, 180)
        self._background = (0, 0, 0)
        self._dim_color = (60, 60, 60)
        self._on_result = None

    def initialize(self, renderer, theme, config=None):
        """Resolve dimensions and button positions."""
        if config is None:
            config = ConfirmDialogConfig()

        r = renderer.radius
        self._cx, self._cy = renderer.centre
        self._prompt_font_size = max(12, int(r * theme.font_size_medium))
        self._label_font_size = max(10, int(r * theme.font_size_small * 1.4))
        self._button_radius = int(r * config.button_radius_fraction)

        dist = int(r * config.button_distance_fraction)
        self._confirm_x, self._confirm_y = radial_position(
            self._cx, self._cy, dist, config.confirm_angle,
        )
        self._cancel_x, self._cancel_y = radial_position(
            self._cx, self._cy, dist, config.cancel_angle,
        )

        self._prompt_text = config.prompt_text
        self._confirm_label = config.confirm_label
        self._cancel_label = config.cancel_label

        self._accent = theme.accent
        self._warning = theme.warning
        self._text_color = theme.text_color
        self._secondary_color = theme.secondary_color
        self._background = theme.background
        self._dim_color = theme.dim_color
        self._focus_index = 0
        self._result = RESULT_PENDING

    def update(self, prompt_text):
        """Update the prompt text."""
        self._prompt_text = prompt_text

    def draw(self, renderer):
        """Render prompt and two option buttons."""
        # Prompt text in upper area.
        renderer.draw_text(
            self._prompt_text,
            self._cx,
            self._cy - int(renderer.radius * 0.25),
            self._prompt_font_size,
            color=self._text_color,
        )

        # Confirm button.
        confirm_focused = self._focus_index == 0
        self._draw_button(
            renderer,
            self._confirm_x, self._confirm_y,
            self._confirm_label,
            self._accent if confirm_focused else self._dim_color,
            confirm_focused,
        )

        # Cancel button.
        cancel_focused = self._focus_index == 1
        self._draw_button(
            renderer,
            self._cancel_x, self._cancel_y,
            self._cancel_label,
            self._warning if cancel_focused else self._dim_color,
            cancel_focused,
        )

    def draw_aod(self, renderer):
        """No AOD for navigation components."""
        pass

    def on_input(self, event):
        """Handle input events for focus and selection."""
        from harness.input_router import InputAction, InputType

        if event.action in (InputAction.UP, InputAction.DOWN):
            self._focus_index = 1 - self._focus_index
        elif event.action == InputAction.ENTER:
            if event.input_type == InputType.TAP and event.x is not None:
                hit = self._hit_test(event.x, event.y)
                if hit is not None:
                    self._result = hit
                    if self._on_result:
                        self._on_result(self._result)
                return
            self._result = (
                RESULT_CONFIRM if self._focus_index == 0 else RESULT_CANCEL
            )
            if self._on_result:
                self._on_result(self._result)
        elif event.action == InputAction.BACK:
            self._result = RESULT_CANCEL
            if self._on_result:
                self._on_result(self._result)

    def get_result(self):
        return self._result

    def _hit_test(self, tap_x, tap_y):
        """Return RESULT_CONFIRM, RESULT_CANCEL, or None."""
        r_sq = self._button_radius * self._button_radius
        dx = tap_x - self._confirm_x
        dy = tap_y - self._confirm_y
        if dx * dx + dy * dy <= r_sq:
            return RESULT_CONFIRM
        dx = tap_x - self._cancel_x
        dy = tap_y - self._cancel_y
        if dx * dx + dy * dy <= r_sq:
            return RESULT_CANCEL
        return None

    def _draw_button(self, renderer, bx, by, label, ring_color, focused):
        """Draw a single circular button."""
        renderer.fill_circle(bx, by, self._button_radius, color=self._background)
        pen = max(2, int(renderer.radius * 0.015))
        if focused:
            pen = max(3, int(renderer.radius * 0.025))
        renderer.set_pen_width(pen)
        renderer.draw_circle(bx, by, self._button_radius, color=ring_color)
        renderer.draw_text(
            label, bx, by,
            self._label_font_size,
            color=self._text_color if focused else self._secondary_color,
        )
