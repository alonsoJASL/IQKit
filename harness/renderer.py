"""T-01 | IQKit Harness Renderer -- pygame drawing primitives.

HarnessRenderer wraps a pygame.Surface and provides drawing methods that
mirror the Garmin Toybox.Graphics.Dc API. Coordinate system: (0,0) at
top-left, same as Garmin Dc. A circular clip mask is applied for round
devices.
"""

import math
from typing import Optional

import pygame

from harness.geometry import arc_points, polygon_from_arc
from harness.layout import screen_centre, screen_radius


class HarnessRenderer:
    """Pygame rendering surface for a single device profile."""

    def __init__(self, device_profile: dict):
        self._profile = device_profile
        self._width = device_profile["resolution"][0]
        self._height = device_profile["resolution"][1]
        self._surface = pygame.Surface((self._width, self._height))
        self._pen_width = 1
        self._color = (255, 255, 255)

        # Precompute layout constants.
        self._radius = screen_radius(self._width, self._height)
        self._cx, self._cy = screen_centre(self._width, self._height)

        # Build circular clip mask for round devices.
        self._clip_mask = None
        if device_profile.get("shape") == "round":
            self._clip_mask = pygame.Surface(
                (self._width, self._height), pygame.SRCALPHA
            )
            self._clip_mask.fill((0, 0, 0, 0))
            pygame.draw.circle(
                self._clip_mask,
                (255, 255, 255, 255),
                (self._cx, self._cy),
                self._radius,
            )

    @property
    def surface(self) -> pygame.Surface:
        return self._surface

    @property
    def width(self) -> int:
        return self._width

    @property
    def height(self) -> int:
        return self._height

    @property
    def radius(self) -> int:
        return self._radius

    @property
    def centre(self) -> tuple[int, int]:
        return (self._cx, self._cy)

    @property
    def device_name(self) -> str:
        return self._profile.get("name", self._profile.get("id", "unknown"))

    def set_color(self, color: tuple[int, int, int]) -> None:
        self._color = color

    def set_pen_width(self, width: int) -> None:
        self._pen_width = max(1, width)

    def clear(self, color: tuple[int, int, int] = (0, 0, 0)) -> None:
        self._surface.fill(color)

    def draw_circle(
        self, cx: int, cy: int, r: int, color: Optional[tuple[int, int, int]] = None
    ) -> None:
        c = color if color is not None else self._color
        pygame.draw.circle(self._surface, c, (cx, cy), r, self._pen_width)

    def fill_circle(
        self, cx: int, cy: int, r: int, color: Optional[tuple[int, int, int]] = None
    ) -> None:
        c = color if color is not None else self._color
        pygame.draw.circle(self._surface, c, (cx, cy), r)

    def draw_arc(
        self,
        cx: int,
        cy: int,
        r: int,
        start_deg: float,
        end_deg: float,
        color: Optional[tuple[int, int, int]] = None,
        num_segments: int = 72,
    ) -> None:
        """Draw an arc as connected line segments."""
        c = color if color is not None else self._color
        points = arc_points(cx, cy, r, start_deg, end_deg, num_segments)
        if len(points) >= 2:
            pygame.draw.lines(self._surface, c, False, points, self._pen_width)

    def draw_line(
        self,
        x1: int,
        y1: int,
        x2: int,
        y2: int,
        color: Optional[tuple[int, int, int]] = None,
    ) -> None:
        c = color if color is not None else self._color
        pygame.draw.line(self._surface, c, (x1, y1), (x2, y2), self._pen_width)

    def draw_text(
        self,
        text: str,
        x: int,
        y: int,
        font_size: int,
        color: Optional[tuple[int, int, int]] = None,
        center: bool = True,
    ) -> None:
        """Render text. If center=True, (x, y) is the centre point."""
        c = color if color is not None else self._color
        font = pygame.font.SysFont("monospace", font_size)
        rendered = font.render(text, True, c)
        if center:
            rect = rendered.get_rect(center=(x, y))
        else:
            rect = rendered.get_rect(topleft=(x, y))
        self._surface.blit(rendered, rect)

    def fill_polygon(
        self,
        points: list[tuple[int, int]],
        color: Optional[tuple[int, int, int]] = None,
    ) -> None:
        if len(points) < 3:
            return
        c = color if color is not None else self._color
        pygame.draw.polygon(self._surface, c, points)

    def apply_clip(self) -> None:
        """Apply the circular clip mask. Call after all drawing is done."""
        if self._clip_mask is not None:
            # Zero out pixels outside the circle.
            clipped = pygame.Surface(
                (self._width, self._height), pygame.SRCALPHA
            )
            clipped.blit(self._surface, (0, 0))
            clipped.blit(
                self._clip_mask, (0, 0), special_flags=pygame.BLEND_RGBA_MIN
            )
            self._surface = clipped

    def get_label_surface(self) -> pygame.Surface:
        """Return a small surface with the device name and resolution."""
        label = f"{self.device_name} ({self._width}x{self._height})"
        font = pygame.font.SysFont("monospace", 14)
        return font.render(label, True, (200, 200, 200))
