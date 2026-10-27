# Fast Lid

A one-click toggle in the Omarchy bar that keeps AI agents working when the
laptop lid is closed.

![Fast Lid](https://img.shields.io/badge/Omarchy-bar%20widget-blue)

## What it does

- **Enabled** — holds a `systemd-inhibit` block lock on `handle-lid-switch` and
  `idle`. Closing the lid no longer suspends the machine, and neither does the
  idle timeout. Agents keep their terminal sessions, network, and CPU.
- **Disabled** — releases the lock and restores the normal lid behavior.

A plain laptop means the hold is on; a slashed laptop means it is off. Click
it once to toggle. The screen still locks normally; only suspend is
suppressed.

## Dependencies

Fast Lid uses the `systemd-inhibit` command already provided by systemd and
Omarchy's `omarchy-notification-send` helper. It does not install packages,
modify system configuration, or require an account or network connection.

## Safety

A closed laptop with running agents can get hot and will drain the battery.
Keep the vents clear, do not leave it running closed inside a bag, and watch
the battery level. An explicit suspend or shutdown, and a critical-battery
action, are **not** blocked.

## Multi-monitor

The inhibitor runs in a single service, shared by every bar surface. Clicking
the icon on any monitor toggles the same machine-wide hold, and every icon
updates from the same state.

## Shell restarts

The inhibitor is owned by the plugin service. If the Omarchy shell restarts or
the plugin is disabled/removed, the process is torn down and the lid returns to
its normal behavior. Click the icon again after a shell restart.

## Install

```bash
omarchy plugin validate ~/.config/omarchy/plugins/clouddown.fast-lid
omarchy-shell shell rescanPlugins
omarchy plugin enable clouddown.fast-lid right --before omarchy.power
```

## Removing

```bash
omarchy plugin disable clouddown.fast-lid
omarchy plugin remove clouddown.fast-lid
```

Disabling the plugin destroys the service, which releases the inhibitor.
Fast Lid writes no persistent files. Removing it leaves no service, process,
configuration change, or other plugin state behind.

## Files

- `manifest.json` — declares the Fast Lid bar widget and its shared service.
- `BarWidget.qml` — the bar icon and click handler.
- `Service.qml` — the single `systemd-inhibit` process and IPC surface.

## License

MIT
