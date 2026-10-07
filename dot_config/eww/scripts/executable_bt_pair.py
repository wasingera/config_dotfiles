#!/usr/bin/env python3
"""Pair with a Bluetooth device: bt_pair.py DEVICE_PATH (a BlueZ object path).
On failure, prints BlueZ's error and exits 1.

Pairing needs an agent to answer BlueZ's questions, and bluetoothctl only
registers one in interactive mode. This one has no input or output ("just
works" pairing, as there's nowhere to show a PIN): it accepts the
confirmation and authorisation requests, since the user picked the device,
and refuses requests to enter a PIN or passkey.
"""

import sys

from gi.repository import Gio, GLib

AGENT_PATH = "/org/eww/bluetooth_agent"
AGENT_XML = """
<node>
  <interface name="org.bluez.Agent1">
    <method name="Release"/>
    <method name="RequestPinCode">
      <arg type="o" direction="in"/><arg type="s" direction="out"/>
    </method>
    <method name="DisplayPinCode">
      <arg type="o" direction="in"/><arg type="s" direction="in"/>
    </method>
    <method name="RequestPasskey">
      <arg type="o" direction="in"/><arg type="u" direction="out"/>
    </method>
    <method name="DisplayPasskey">
      <arg type="o" direction="in"/><arg type="u" direction="in"/><arg type="q" direction="in"/>
    </method>
    <method name="RequestConfirmation">
      <arg type="o" direction="in"/><arg type="u" direction="in"/>
    </method>
    <method name="RequestAuthorization">
      <arg type="o" direction="in"/>
    </method>
    <method name="AuthorizeService">
      <arg type="o" direction="in"/><arg type="s" direction="in"/>
    </method>
    <method name="Cancel"/>
  </interface>
</node>
"""
REFUSED = {"RequestPinCode", "RequestPasskey", "DisplayPinCode", "DisplayPasskey"}


def on_agent_call(bus, sender, path, interface, method, params, invocation):
    if method in REFUSED:
        invocation.return_dbus_error("org.bluez.Error.Rejected", "Needs a PIN or passkey")
    else:
        invocation.return_value(None)


def main():
    device = sys.argv[1]
    bus = Gio.bus_get_sync(Gio.BusType.SYSTEM)
    interface = Gio.DBusNodeInfo.new_for_xml(AGENT_XML).interfaces[0]
    bus.register_object_with_closures2(AGENT_PATH, interface, on_agent_call, None, None)

    loop = GLib.MainLoop()
    error = None

    def paired(bus, result):
        nonlocal error
        try:
            bus.call_finish(result)
        except GLib.Error as e:
            error = e
        loop.quit()

    try:
        bus.call_sync(
            "org.bluez", "/org/bluez", "org.bluez.AgentManager1", "RegisterAgent",
            GLib.Variant("(os)", (AGENT_PATH, "NoInputNoOutput")),
            None, Gio.DBusCallFlags.NONE, -1,
        )
    except GLib.Error as e:
        sys.exit(e.message)
    # Pair from the connection the agent is on, so BlueZ asks this agent
    bus.call(
        "org.bluez", device, "org.bluez.Device1", "Pair", None, None,
        Gio.DBusCallFlags.NONE, 60_000, None, paired,
    )
    loop.run()
    if error:
        # e.g. "GDBus.Error:org.bluez.Error.AuthenticationFailed: Authentication Failed"
        sys.exit(error.message.rsplit(": ", 1)[-1])


if __name__ == "__main__":
    main()
