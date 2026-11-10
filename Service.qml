import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

// One shared inhibitor for every bar surface. A bar is instantiated once per
// monitor; keeping the process and its state here means clicking the icon on
// any screen toggles the same machine-wide hold, and disabling or removing the
// plugin tears the service down and releases the lock automatically.
Item {
  id: root

  readonly property bool held: inhibitor.running
  property bool wantHeld: false
  property string lastError: ""

  function setHeld(next) {
    next = !!next
    if (next === wantHeld && next === held) return

    wantHeld = next
    lastError = ""

    if (next) {
      if (!inhibitor.running) inhibitor.running = true
    } else {
      if (inhibitor.running) inhibitor.running = false
    }
  }

  function toggle() {
    setHeld(!held)
  }

  // Only failures warrant a desktop notification. Success is shown at the bar.
  function notify(title, body, urgency) {
    var args = [
      "/usr/share/omarchy/bin/omarchy-notification-send",
      "--app-name", "Fast Lid",
      "-u", urgency || "low",
      "-t", "6000",
      title
    ]
    if (body) args.push(body)
    Quickshell.execDetached(args)
  }

  // logind treats a block inhibitor on handle-lid-switch as a reason to ignore
  // the lid entirely. idle is inhibited too, so an unattended machine does not
  // suspend on its idle timeout while agents are still working. sleep is
  // deliberately not inhibited: an explicit suspend or shutdown still works,
  // and a critical battery can still take the machine down safely.
  Process {
    id: inhibitor
    running: false
    command: [
      "/usr/bin/systemd-inhibit",
      "--what=handle-lid-switch:idle",
      "--who=Omarchy Fast Lid",
      "--why=Keep agents working while the laptop lid is closed",
      "--mode=block",
      "sleep", "infinity"
    ]

    onExited: function(exitCode) {
      if (!root.wantHeld) return

      root.wantHeld = false
      root.lastError = "systemd-inhibit exited unexpectedly"
      root.notify("Lid hold failed", root.lastError, "critical")
    }
  }

  Component.onDestruction: {
    root.wantHeld = false
    if (inhibitor.running) inhibitor.running = false
  }

  ShellIpc {
    target: "clouddown.fast-lid"

    function status(): string {
      return root.held ? "enabled" : "disabled"
    }

    function enable(): string {
      root.setHeld(true)
      return root.held ? "enabled" : "starting"
    }

    function disable(): string {
      root.setHeld(false)
      return "disabled"
    }

    function toggle(): string {
      root.setHeld(!root.held)
      return root.held ? "enabled" : "disabled"
    }
  }
}
