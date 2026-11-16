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
  // 0 is off; 33 is unlimited; other values are 15-minute increments.
  property int durationStep: 0
  property double expiresAt: 0
  property int remainingSeconds: 0

  function updateCountdown() {
    remainingSeconds = expiresAt > 0 ? Math.max(0, Math.ceil((expiresAt - Date.now()) / 1000)) : 0
    if (expiresAt > 0 && remainingSeconds === 0) setHeld(false)
  }

  function setDuration(step) {
    step = Math.max(0, Math.min(33, Math.round(Number(step) || 0)))
    durationStep = step
    expiresAt = step > 0 && step < 33 ? Date.now() + step * 15 * 60 * 1000 : 0
    updateCountdown()
    setHeld(step > 0)
  }

  function setHeld(next) {
    next = !!next
    if (next === wantHeld && next === held) return

    wantHeld = next
    lastError = ""

    if (next) {
      if (durationStep === 0) durationStep = 33
      if (!inhibitor.running) inhibitor.running = true
    } else {
      durationStep = 0
      expiresAt = 0
      remainingSeconds = 0
      if (inhibitor.running) inhibitor.running = false
    }
  }

  function toggle() {
    setHeld(!held)
  }

  Timer {
    interval: 1000
    repeat: true
    running: root.expiresAt > 0
    onTriggered: root.updateCountdown()
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
      root.durationStep = 0
      root.expiresAt = 0
      root.remainingSeconds = 0
      root.lastError = "systemd-inhibit exited unexpectedly"
      Quickshell.execDetached([
        "/usr/share/omarchy/bin/omarchy-notification-send",
        "--app-name", "Fast Lid", "-u", "critical", "-t", "6000",
        "Lid hold failed", root.lastError
      ])
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
