"""D-03 | IQKitCentreMetric -- Python harness implementation.

Large primary value + unit label, vertically centred on screen.
Typical use: heart rate, body battery, HRV status.

Interface: IQKit Component Interface v1
"""

from harness.layout import screen_centre, screen_radius


class CentreMetric:
    """Display-only component: large value text with a smaller unit label."""

    def __init__(self):
        self._cx = 0
        self._cy = 0
        self._value_font_size = 0
        self._unit_font_size = 0
        self._value_offset_y = 0
        self._unit_offset_y = 0
        self._primary_color = (255, 255, 255)
        self._secondary_color = (180, 180, 180)
        self._dim_color = (60, 60, 60)
        self._background = (0, 0, 0)
        self._value_text = "--"
        self._unit_text = ""

    def initialize(self, renderer, theme):
        """Resolve all fractional dimensions to integers."""
        r = renderer.radius
        self._cx, self._cy = renderer.centre
        self._value_font_size = max(12, int(r * theme.font_size_large * 2.0))
        self._unit_font_size = max(10, int(r * theme.font_size_medium))
        self._value_offset_y = -int(r * 0.06)
        self._unit_offset_y = int(r * 0.14)
        self._primary_color = theme.text_color
        self._secondary_color = theme.secondary_color
        self._dim_color = theme.dim_color
        self._background = theme.background

    def update(self, value_text, unit_text):
        """Set the displayed value and unit strings."""
        self._value_text = value_text
        self._unit_text = unit_text

    def draw(self, renderer):
        """Render the metric at full brightness."""
        renderer.draw_text(
            self._value_text,
            self._cx,
            self._cy + self._value_offset_y,
            self._value_font_size,
            color=self._primary_color,
        )
        renderer.draw_text(
            self._unit_text,
            self._cx,
            self._cy + self._unit_offset_y,
            self._unit_font_size,
            color=self._secondary_color,
        )

    def draw_aod(self, renderer):
        """Render AOD variant with dim colours."""
        renderer.draw_text(
            self._value_text,
            self._cx,
            self._cy + self._value_offset_y,
            self._value_font_size,
            color=self._dim_color,
        )
        renderer.draw_text(
            self._unit_text,
            self._cx,
            self._cy + self._unit_offset_y,
            self._unit_font_size,
            color=self._dim_color,
        )
