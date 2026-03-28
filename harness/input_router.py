"""F-04 | IQKit.InputRouter -- Python harness implementation.

Unified input event dispatcher. Normalises pygame keyboard and mouse events
into a common IQKitInputEvent that components consume uniformly.

In the Monkey C implementation, this normalises Toybox key/tap/swipe events.
"""

from dataclasses import dataclass
from enum import Enum, auto
from typing import Optional

import pygame


class InputType(Enum):
    KEY = auto()
    TAP = auto()


class InputAction(Enum):
    UP = auto()
    DOWN = auto()
    ENTER = auto()
    BACK = auto()


@dataclass(frozen=True)
class IQKitInputEvent:
    """Normalised input event consumed by components."""

    input_type: InputType
    action: InputAction
    x: Optional[int] = None  # Pixel coordinate, TAP events only.
    y: Optional[int] = None


# Pygame key -> InputAction mapping.
_KEY_MAP = {
    pygame.K_UP: InputAction.UP,
    pygame.K_DOWN: InputAction.DOWN,
    pygame.K_RETURN: InputAction.ENTER,
    pygame.K_KP_ENTER: InputAction.ENTER,
    pygame.K_ESCAPE: InputAction.BACK,
}


class InputRouter:
    """Receives pygame events, normalises them, and dispatches to the
    focused component.

    Components register themselves via add_target(). The router tracks
    which target has focus and routes events to it.
    """

    def __init__(self):
        self._targets = []
        self._focus_index = -1

    def add_target(self, target) -> None:
        """Register a component as an input target.

        The target must implement on_input(event: IQKitInputEvent).
        """
        self._targets.append(target)
        if self._focus_index < 0:
            self._focus_index = 0

    @property
    def focused_target(self):
        if 0 <= self._focus_index < len(self._targets):
            return self._targets[self._focus_index]
        return None

    def move_focus(self, delta: int) -> None:
        """Move focus by delta positions (wraps around)."""
        if not self._targets:
            return
        self._focus_index = (self._focus_index + delta) % len(self._targets)

    def process_pygame_event(self, event: pygame.event.Event) -> Optional[IQKitInputEvent]:
        """Convert a pygame event to an IQKitInputEvent and dispatch it.

        Returns the normalised event if one was produced, None otherwise.
        """
        normalised = None

        if event.type == pygame.KEYDOWN and event.key in _KEY_MAP:
            normalised = IQKitInputEvent(
                input_type=InputType.KEY,
                action=_KEY_MAP[event.key],
            )
        elif event.type == pygame.MOUSEBUTTONDOWN and event.button == 1:
            normalised = IQKitInputEvent(
                input_type=InputType.TAP,
                action=InputAction.ENTER,
                x=event.pos[0],
                y=event.pos[1],
            )

        if normalised is not None:
            target = self.focused_target
            if target is not None and hasattr(target, "on_input"):
                target.on_input(normalised)

        return normalised
