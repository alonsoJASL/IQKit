"""F-02 | IQKit.Theme -- Python harness implementation.

Centralised colour palette, font size tokens, and stroke weight tokens.
Theme is a data contract, not a singleton. Callers construct an instance
and inject it into components at initialize() time.
"""

from dataclasses import dataclass


@dataclass(frozen=True)
class IQKitThemeTokens:
    """Immutable theme token set injected into components."""

    # Colours as (R, G, B) tuples for pygame.
    primary_color: tuple[int, int, int]
    secondary_color: tuple[int, int, int]
    background: tuple[int, int, int]
    text_color: tuple[int, int, int]
    accent: tuple[int, int, int]
    warning: tuple[int, int, int]
    dim_color: tuple[int, int, int]  # AOD low-brightness colour

    # Font sizes as fractions of screen_radius, resolved to pixels by caller.
    font_size_large: float
    font_size_medium: float
    font_size_small: float

    # Stroke weights as fractions of screen_radius.
    stroke_weight_thick: float
    stroke_weight_thin: float


def default_theme() -> IQKitThemeTokens:
    """AMOLED-optimised defaults: light on black, green accent."""
    return IQKitThemeTokens(
        primary_color=(255, 255, 255),
        secondary_color=(180, 180, 180),
        background=(0, 0, 0),
        text_color=(255, 255, 255),
        accent=(0, 200, 80),          # Garmin-esque green
        warning=(255, 80, 40),
        dim_color=(60, 60, 60),       # AOD
        font_size_large=0.14,
        font_size_medium=0.09,
        font_size_small=0.06,
        stroke_weight_thick=0.03,
        stroke_weight_thin=0.01,
    )
