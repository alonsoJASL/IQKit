"""F-01 | IQKit.Geometry -- Python harness implementation.

Polar-to-cartesian conversion, arc segment math, polygon approximation.
All functions are pure: no side effects, no platform dependencies.
The Monkey C implementation in src/foundation/IQKitGeometry.mc must produce
identical output for the same inputs.
"""

import math


def polar_to_cartesian(
    cx: float, cy: float, r: float, angle_deg: float
) -> tuple[int, int]:
    """Convert polar coordinates to cartesian pixel coordinates.

    Args:
        cx: Centre x in pixels.
        cy: Centre y in pixels.
        r: Radius in pixels.
        angle_deg: Angle in degrees. 0 = right (3 o'clock), 90 = down,
            270 = up (12 o'clock on a watch face).

    Returns:
        (x, y) as integers, suitable for pixel-level rendering.
    """
    angle_rad = math.radians(angle_deg)
    x = cx + r * math.cos(angle_rad)
    y = cy + r * math.sin(angle_rad)
    return (int(round(x)), int(round(y)))


def arc_points(
    cx: float,
    cy: float,
    r: float,
    start_deg: float,
    end_deg: float,
    num_segments: int = 36,
) -> list[tuple[int, int]]:
    """Generate a sequence of cartesian points along an arc.

    Points are evenly spaced from start_deg to end_deg (inclusive of both
    endpoints). Useful for approximating arcs with line segments.

    Args:
        cx: Centre x.
        cy: Centre y.
        r: Radius.
        start_deg: Start angle in degrees.
        end_deg: End angle in degrees.
        num_segments: Number of line segments (num_segments + 1 points).

    Returns:
        List of (x, y) integer tuples.
    """
    if num_segments < 1:
        num_segments = 1
    step = (end_deg - start_deg) / num_segments
    return [
        polar_to_cartesian(cx, cy, r, start_deg + i * step)
        for i in range(num_segments + 1)
    ]


def polygon_from_arc(
    cx: float,
    cy: float,
    r_inner: float,
    r_outer: float,
    start_deg: float,
    end_deg: float,
    num_segments: int = 36,
) -> list[tuple[int, int]]:
    """Generate a closed polygon approximating an arc band (annular sector).

    The polygon traces the outer arc from start to end, then the inner arc
    from end back to start, forming a closed ring segment suitable for
    fillPolygon.

    Args:
        cx: Centre x.
        cy: Centre y.
        r_inner: Inner radius.
        r_outer: Outer radius.
        start_deg: Start angle in degrees.
        end_deg: End angle in degrees.
        num_segments: Segments per arc edge.

    Returns:
        List of (x, y) integer tuples forming a closed polygon.
    """
    outer = arc_points(cx, cy, r_outer, start_deg, end_deg, num_segments)
    inner = arc_points(cx, cy, r_inner, end_deg, start_deg, num_segments)
    return outer + inner
