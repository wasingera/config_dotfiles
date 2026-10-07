#!/usr/bin/env python3
"""Print where a dropdown menu should hang from the eww bar: "RIGHT TOP", the
gaps in logical px from the right edge of the bar's monitor to the right edge
of the bar button under the pointer, and from the monitor's top to the
button's bottom.

The button's geometry comes from GTK itself, through the accessibility bus
(AT-SPI), so nothing needs measuring when the bar changes. Without it, the
pointer stands in for the button's right edge.
"""

import json
import os
import subprocess
import sys

import gi
from gi.repository import Gio, GLib

# :namespace of the bar's window in eww.yuck
BAR_NAMESPACE = "eww-bar"


def hyprctl(*args):
    out = subprocess.run(
        ["hyprctl", "-j", *args], capture_output=True, text=True, check=True
    ).stdout
    return json.loads(out)


def find_bar():
    """The bar's monitor and layer-shell surface, as hyprctl reports them"""
    for name, monitor_layers in hyprctl("layers").items():
        for layers in monitor_layers["levels"].values():
            for layer in layers:
                if layer["namespace"] == BAR_NAMESPACE:
                    monitors = hyprctl("monitors")
                    return next(m for m in monitors if m["name"] == name), layer
    sys.exit(f"no {BAR_NAMESPACE} layer")


def accessibility_bus_reachable():
    """Whether libatspi will reach the accessibility bus. When it can't, it
    aborts the whole process rather than raising."""
    try:
        address = os.environ.get("AT_SPI_BUS_ADDRESS")
        if not address:
            session = Gio.bus_get_sync(Gio.BusType.SESSION)
            reply = session.call_sync(
                "org.a11y.Bus", "/org/a11y/bus", "org.a11y.Bus", "GetAddress",
                None, GLib.VariantType("(s)"), Gio.DBusCallFlags.NONE, 1000,
            )
            address = reply.unpack()[0]
        Gio.DBusConnection.new_for_address_sync(
            address,
            Gio.DBusConnectionFlags.AUTHENTICATION_CLIENT
            | Gio.DBusConnectionFlags.MESSAGE_BUS_CONNECTION,
        ).close_sync()
        return True
    except GLib.Error:
        return False


def pill_extents(width, height, x, y):
    """Extents of the bar's pill at (x, y), relative to the bar's window,
    which is width x height. The pill is the innermost widget there that
    spans the bar's full height: its contents sit inside its padding. Its
    extents include its margin, which the bar's pills have on the left only.
    None if the point isn't on the bar."""
    if not accessibility_bus_reachable():
        raise RuntimeError("can't reach the accessibility bus")
    gi.require_version("Atspi", "2.0")
    from gi.repository import Atspi

    coords = Atspi.CoordType.WINDOW

    def children(node, showing=True):
        for i in range(node.get_child_count()):
            child = node.get_child_at_index(i)
            if child and (
                not showing or child.get_state_set().contains(Atspi.StateType.SHOWING)
            ):
                yield child

    def contains(extents):
        return (
            extents.x <= x < extents.x + extents.width
            and extents.y <= y < extents.y + extents.height
        )

    # Applications have no states; their windows and widgets do
    for app in children(Atspi.get_desktop(0), showing=False):
        if app.get_name() != "eww":
            continue
        for frame in children(app):
            extents = frame.get_extents(coords)
            if (extents.width, extents.height) != (width, height) or not contains(extents):
                continue
            pill, node = None, frame
            while node:
                extents = node.get_extents(coords)
                if extents.y == 0 and extents.height == height:
                    pill = extents
                node = next((c for c in children(node) if contains(c.get_extents(coords))), None)
            return pill
    return None


def main():
    try:
        monitor, bar = find_bar()
        pointer = hyprctl("cursorpos")
    except (OSError, subprocess.CalledProcessError):
        sys.exit("bar_anchor: hyprctl failed; not in Hyprland?")

    # In logical px; width and height swap when the monitor is rotated
    width = monitor["height"] if monitor["transform"] % 2 else monitor["width"]
    monitor_right = monitor["x"] + width / monitor["scale"]

    try:
        pill = pill_extents(bar["w"], bar["h"], pointer["x"] - bar["x"], pointer["y"] - bar["y"])
    except Exception as error:  # no accessibility bus, GTK's bridge disabled, ...
        print(f"bar_anchor: {error}", file=sys.stderr)
        pill = None

    if pill:
        right = bar["x"] + pill.x + pill.width
        bottom = bar["y"] + pill.y + pill.height
    else:
        right = pointer["x"]
        bottom = bar["y"] + bar["h"]
    print(round(monitor_right - right), round(bottom - monitor["y"]))


if __name__ == "__main__":
    main()
