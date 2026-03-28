"""F-03 | IQKit.Layout -- Python harness implementation.

Screen radius computation, safe-area insets, radial grid helper.
All functions are pure. Layout depends on geometry for coordinate conversion.
"""

import math

from harness.geometry import polar_to_cartesian


def screen_radius(width: int, height: int) -> int:
    """Compute the base layout unit from screen dimensions.

    For round screens: floor of the shorter dimension divided by 2.
    This is THE canonical unit for all fractional layout in IQKit.
    """
    return math.floor(min(width, height) / 2)


def screen_centre(width: int, height: int) -> tuple[int, int]:
    """Compute the screen centre point."""
    return (width // 2, height // 2)


def safe_area_inset(radius: int, fraction: float = 0.05) -> int:
    """Compute the bezel margin in pixels.

    Default 5% of screen radius -- keeps content clear of the physical
    bezel edge on round devices.
    """
    return max(1, int(radius * fraction))


def radial_position(
    cx: int, cy: int, radius: float, angle_deg: float
) -> tuple[int, int]:
    """Convenience wrapper: place an element at a polar coordinate."""
    return polar_to_cartesian(cx, cy, radius, angle_deg)
