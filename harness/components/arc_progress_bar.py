"""D-01 | IQKitArcProgressBar -- Python harness implementation.

Single-value arc indicator (e.g. Body Battery, HRV). Renders a background
track arc and a fill arc proportional to a 0.0-1.0 progress value.
Start/end angle configurable.

Interface: IQKit Component Interface v1
"""

from dataclasses import dataclass
from typing import Optional

from harness.geometry import arc_points, polar_to_cartesian, polygon_from_arc


@dataclass(frozen=True)
class ArcProgressBarConfig:
    """Configuration injected at initialize() time."""

    start_angle: float = 135.0
    end_angle: float = 405.0
    radius_fraction: float = 0.70
    thickness_fraction: float = 0.08
    track_color: Optional[tuple] = None
    fill_color: Optional[tuple] = None


class ArcProgressBar:
    """Display-only component: arc-shaped progress indicator."""

    def __init__(self):
        self._cx = 0
        self._cy = 0
        self._r_inner = 0
        self._r_outer = 0
        self._r_mid = 0
        self._start_angle = 135.0
        self._end_angle = 405.0
        self._num_segments = 72
        self._track_polygon = []
        self._fill_polygon = []
        self._track_color = (60, 60, 60)
        self._fill_color = (0, 200, 80)
        self._dim_color = (60, 60, 60)
        self._background = (0, 0, 0)
        self._progress = 0.0
        self._marker_x = 0
        self._marker_y = 0

    def initialize(self, renderer, theme, config=None):
        """Resolve all fractional dimensions and pre-compute track polygon."""
        if config is None:
            config = ArcProgressBarConfig()

        r = renderer.radius
        self._cx, self._cy = renderer.centre
        self._start_angle = config.start_angle
        self._end_angle = config.end_angle

        half_thick = int(r * config.thickness_fraction / 2)
        mid_r = int(r * config.radius_fraction)
        self._r_mid = mid_r
        self._r_inner = mid_r - half_thick
        self._r_outer = mid_r + half_thick

        self._track_color = config.track_color or theme.dim_color
        self._fill_color = config.fill_color or theme.accent
        self._dim_color = theme.dim_color
        self._background = theme.background

        self._track_polygon = polygon_from_arc(
            self._cx, self._cy,
            self._r_inner, self._r_outer,
            self._start_angle, self._end_angle,
            self._num_segments,
        )
        self._fill_polygon = []
        self._marker_x, self._marker_y = polar_to_cartesian(
            self._cx, self._cy, self._r_mid, self._start_angle,
        )

    def update(self, progress):
        """Set progress value (0.0 to 1.0). Recomputes fill polygon."""
        self._progress = max(0.0, min(1.0, progress))
        sweep = self._end_angle - self._start_angle
        fill_end = self._start_angle + self._progress * sweep

        if self._progress > 0.001:
            seg_count = max(4, int(self._num_segments * self._progress))
            self._fill_polygon = polygon_from_arc(
                self._cx, self._cy,
                self._r_inner, self._r_outer,
                self._start_angle, fill_end,
                seg_count,
            )
        else:
            self._fill_polygon = []

        self._marker_x, self._marker_y = polar_to_cartesian(
            self._cx, self._cy, self._r_mid, fill_end,
        )

    def draw(self, renderer):
        """Render track and fill arcs."""
        renderer.fill_polygon(self._track_polygon, color=self._track_color)
        if self._fill_polygon:
            renderer.fill_polygon(self._fill_polygon, color=self._fill_color)

    def draw_aod(self, renderer):
        """AOD: thin arc outline + dot marker at fill position."""
        pen = max(1, int(renderer.radius * 0.005))
        renderer.set_pen_width(pen)
        renderer.draw_arc(
            self._cx, self._cy, self._r_mid,
            self._start_angle, self._end_angle,
            color=self._dim_color,
        )
        dot_r = max(2, int(renderer.radius * 0.015))
        renderer.fill_circle(
            self._marker_x, self._marker_y, dot_r,
            color=self._dim_color,
        )
