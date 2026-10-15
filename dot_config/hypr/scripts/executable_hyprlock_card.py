#!/usr/bin/env python3
"""Render hyprlock's glass card: the wallpaper behind it, blurred and tinted.

hyprlock can only blur its whole background, not what's behind one widget. So this
renders the part of the wallpaper that the card covers, blurred, and tints it with the
scheme's base colour; hyprlock.conf draws it as an image behind the card's text.

The tint is as opaque as the text needs: at least $card_opacity, and more if the
wallpaper behind the card would leave $dim_text (the dimmest small text on it) below
$card_contrast : 1. A light card over a dark wallpaper needs much more than a dark one.

The card's geometry ($card_x, $card_y, $card_w, $card_h), blur radius ($card_blur) and
those settings are read from ~/.config/hypr/hyprlock.conf; the palette and wallpaper
from the current colour scheme's hyprlock.conf; the screen size from Hyprland (one
monitor assumed). colorscheme runs this whenever it switches mode or wallpaper, which
change the card's colours.
"""

import json
import math
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
RGB = re.compile(r"^rgba?\(([0-9a-fA-F]{6})(?:[0-9a-fA-F]{2})?\)$")


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


def colour(values, name):
    """A colour variable such as rgb(1e1e2e), or a $reference to one, as (r, g, b)."""
    value = values[name]
    while value.startswith("$"):
        value = values[value[1:]]
    if not (match := RGB.match(value)):
        raise ValueError(f"${name} isn't an rgb() colour: {value}")
    digits = match.group(1)
    return tuple(int(digits[i : i + 2], 16) for i in (0, 2, 4))


def luminance(rgb):
    """WCAG relative luminance of an sRGB colour."""

    def linear(channel):
        channel /= 255
        return channel / 12.92 if channel <= 0.04045 else ((channel + 0.055) / 1.055) ** 2.4

    r, g, b = (linear(channel) for channel in rgb)
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def contrast(a, b):
    """WCAG contrast ratio of two colours, from 1 to 21."""
    lighter, darker = sorted((luminance(a), luminance(b)), reverse=True)
    return (lighter + 0.05) / (darker + 0.05)


def tint_opacity(backdrop, tint, text, minimum, target):
    """The least opacity of tint over backdrop, in 1/255 steps, at which text reaches the
    target contrast everywhere; at least minimum."""
    # the backdrop is blurred, so a few thousand samples see everything in it
    samples = list(backdrop.reduce(8).get_flattened_data())

    def readable(step):
        alpha = step / 255
        return all(
            contrast(text, [alpha * t + (1 - alpha) * s for t, s in zip(tint, sample)]) >= target
            for sample in samples
        )

    if not readable(255):
        print(
            f"hyprlock_card: even an opaque card leaves its text below {target}:1",
            file=sys.stderr,
        )
        return 1.0
    # more tint brings every sample towards the tint, which is readable, so search by halves
    low, high = math.ceil(minimum * 255), 255
    while low < high:
        middle = (low + high) // 2
        if readable(middle):
            high = middle
        else:
            low = middle + 1
    return low / 255


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

    base = colour(config, "base")
    opacity = tint_opacity(
        card,
        base,
        colour(config, "dim_text"),
        float(config["card_opacity"]),
        float(config["card_contrast"]),
    )
    card = Image.blend(card, Image.new("RGB", card.size, base), opacity)

    temporary = OUTPUT.with_name(f".{OUTPUT.name}.tmp")
    card.save(temporary, "PNG")
    temporary.replace(OUTPUT)


if __name__ == "__main__":
    try:
        main()
    except (OSError, KeyError, ValueError, subprocess.CalledProcessError) as error:
        sys.exit(f"hyprlock_card: {error}")
