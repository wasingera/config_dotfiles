#!/usr/bin/env python3
"""Wrap TEXT for a rofi message (-mesg) in THEME: print it as pango markup,
broken into lines that fit the menu.

rofi wraps a message itself, but inside the dropdown's horizontal menu-row
(rofi/dropdown.rasi) it measures the height for the whole screen's width:
one line. The menu box then doesn't grow, and the lines overlap the entry.
With the breaks already in, rofi's measurement is right.

The width (menu-width less textbox's padding) and the font come from the
theme as rofi resolves it (-dump-theme), so they follow the theme.

    rofi_wrap.py ~/.config/rofi/wifi_password/theme.rasi "Password for X"
"""

import re
import subprocess
import sys

import gi

gi.require_version("Pango", "1.0")
gi.require_version("PangoCairo", "1.0")
from gi.repository import GLib, Pango, PangoCairo  # noqa: E402


def theme_values(theme):
    """Return (menu-width, textbox's left + right padding, textbox's font)."""
    dump = subprocess.run(
        ["rofi", "-theme", theme, "-dump-theme"],
        capture_output=True, text=True, check=True,
    ).stdout
    width = int(re.search(r"menu-width:\s*(\d+)px", dump)[1])
    textbox = re.search(r"^textbox\s*\{(.*?)^\}", dump, re.M | re.S)[1]
    font = re.search(r'font:\s*"([^"]+)"', textbox)[1]
    # padding: all | vertical horizontal | top horizontal bottom | top right bottom left
    pad = [int(p) for p in re.findall(r"(\d+)px", re.search(r"padding:([^;]*);", textbox)[1])]
    left, right = {1: (0, 0), 2: (1, 1), 3: (1, 1), 4: (3, 1)}[len(pad)]
    return width, pad[left] + pad[right], font


def wrap(text, width, font):
    layout = Pango.Layout.new(PangoCairo.FontMap.get_default().create_context())
    layout.set_font_description(Pango.FontDescription.from_string(font))
    layout.set_width(width * Pango.SCALE)
    layout.set_wrap(Pango.WrapMode.WORD_CHAR)
    layout.set_text(text, -1)
    data = text.encode()
    return [
        data[line.start_index : line.start_index + line.length].decode().rstrip()
        for line in layout.get_lines_readonly()
    ]


def main():
    theme, text = sys.argv[1:]
    width, padding, font = theme_values(theme)
    lines = wrap(text, width - padding, font)
    print("\n".join(GLib.markup_escape_text(line, -1) for line in lines))


main()
