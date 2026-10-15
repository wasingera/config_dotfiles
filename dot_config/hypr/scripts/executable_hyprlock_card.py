#!/usr/bin/env python3
"""Render the frosted backdrop of hyprlock's glass card.

hyprlock can only blur its whole background, not what's behind one widget. So this
renders the part of the wallpaper that the card covers, blurred, and hyprlock.conf
draws it as an image under the card's translucent panel.

The card's geometry ($card_x, $card_y, $card_w, $card_h) and blur radius ($card_blur)
are read from ~/.config/hypr/hyprlock.conf, the wallpaper from the current colour
scheme's hyprlock.conf, and the screen size from Hyprland (one monitor assumed).
colorscheme runs this whenever it switches mode, since each mode has its own wallpaper.
"""

import json
import os
import re
import subprocess
import sys
from pathlib import Path

from PIL import Image, ImageFilter, ImageOps

HOME = Path.home()
LAYOUT = Path(os.environ.get("XDG_CONFIG_HOME", HOME / ".config")) / "hypr/hyprlock.conf"
CURRENT = Path(os.environ.get("XDG_STATE_HOME", HOME / ".local/state")) / "colorscheme/current"
OUTPUT = CURRENT / "hyprlock-card.png"

VARIABLE = re.compile(r"^\$(\w+)\s*=\s*(.*?)\s*$")
# hyprlang arithmetic: one operation on two numbers or variable names
EXPRESSION = re.compile(r"^\{\{\s*([\w.-]+)\s+([-+*/])\s+([\w.-]+)\s*\}\}$")
OPERATIONS = {
    "+": lambda a, b: a + b,
    "-": lambda a, b: a - b,
    "*": lambda a, b: a * b,
    "/": lambda a, b: a / b,
}


def variables(*paths):
    """The $variables defined in hyprlang files, with arithmetic evaluated."""
    values = {}

    def operand(token):
        try:
            return float(token)
        except ValueError:
            return float(values[token])

    for path in paths:
        for line in path.read_text().splitlines():
            if not (match := VARIABLE.match(line)):
                continue
            name, value = match.groups()
            if expression := EXPRESSION.match(value):
                a, op, b = expression.groups()
                value = OPERATIONS[op](operand(a), operand(b))
            values[name] = value
    return values


def screen_size():
    monitors = json.loads(subprocess.check_output(["hyprctl", "monitors", "-j"]))
    return monitors[0]["width"], monitors[0]["height"]


def main():
    config = variables(CURRENT / "hyprlock.conf", LAYOUT)
    wallpaper = Path(os.path.expanduser(config["wallpaper"]))
    if not wallpaper.is_file():
        # hyprlock shows the plain base colour instead, so there's nothing to blur
        OUTPUT.unlink(missing_ok=True)
        return

    width, height = screen_size()
    x, y, w, h, radius = (
        float(config[name]) for name in ("card_x", "card_y", "card_w", "card_h", "card_blur")
    )
    # hyprlock covers the screen with the wallpaper, centred, and measures
    # positions in screen pixels from the centre, y pointing up
    screen = ImageOps.fit(Image.open(wallpaper).convert("RGB"), (width, height))
    left, top = round(x), round(height / 2 - y - h / 2)
    # blur a margin around the card too, so its edges get the same blur as its middle
    margin = round(3 * radius)
    region = screen.crop((left - margin, top - margin, left + round(w) + margin, top + round(h) + margin))
    region = region.filter(ImageFilter.GaussianBlur(radius))
    card = region.crop((margin, margin, margin + round(w), margin + round(h)))

    temporary = OUTPUT.with_name(f".{OUTPUT.name}.tmp")
    card.save(temporary, "PNG")
    temporary.replace(OUTPUT)


if __name__ == "__main__":
    try:
        main()
    except (OSError, KeyError, ValueError, subprocess.CalledProcessError) as error:
        sys.exit(f"hyprlock_card: {error}")
