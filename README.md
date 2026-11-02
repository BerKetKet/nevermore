# 🦅 Nevermore Control Center

> *"Quoth the Raven, 'Nevermore.'"* — Edgar Allan Poe

**Nevermore** is an advanced, modular, and aesthetic slide-out **Control Center** for **KDE Plasma 6 (Wayland)**. Built to transcend the limitations of sparse desktop applets, Nevermore delivers a unified, high-density dashboard inspired by Budgie's *Raven* and macOS *Control Center*—engineered to be the definitive control center for KDE Plasma.

---

## 📊 Feature Status Matrix

| Feature | Status | Notes |
| :--- | :--- | :--- |
| **Segmented Tab Flyout** | **Implemented** | Three dedicated tabs: Widgets, Notifications, and Run. |
| **Interactive Calendar** | **Implemented** | Full 7x6 month grid with month navigation and current day highlight. |
| **Overall CPU Telemetry** | **Implemented** | Aggregate CPU load percentage via `org.kde.ksysguard.sensors`. |
| **Per-Core CPU Stats** | *Planned* | Per-core CPU load breakdown is scheduled for a future release. |
| **RAM Telemetry** | **Implemented** | Real-time memory consumption (`Used GB / Total GB`) and percentage. |
| **Storage Utilization** | **Implemented** | Aggregate storage utilization across mounted filesystems (`disk/all`). |
| **Network Throughput** | **Implemented** | Real-time aggregate upload and download throughput. |
| **MPRIS Media Controller** | **Implemented** | Player detection, album artwork, track details, and playback controls. |
| **Audio Volume Controls** | **Implemented** | Master output and microphone volume sliders with toggle mute. |
| **Notification Center** | **Implemented** | Aggregated notification feed with Do Not Disturb and bulk clearing. |
| **Notification Actions** | *Partial* | Per-notification dismissal works; action buttons planned for Phase 5. |
| **Notification Timestamps**| *Planned* | Relative timestamps ("5m ago") scheduled for Phase 5. |
| **Expandable Notifications**| *Planned* | Collapsible long-body notification cards scheduled for Phase 5. |
| **Quick Run Tab** | **Implemented** | One-shot command runner with exit codes, directory tracking, and process group control. |
| **Process Group Termination** | **Implemented** | Stop button terminates entire process group using `setsid` and `kill -TERM` then `kill -KILL`. |
| **Background Tasks** | **Implemented** | Launch, list (`--output=json`), inspect logs, stop active units, and dismiss finished/failed units (`nevermore-task-*`). |
| **Multiline Paste Protection**| **Implemented** | Clipboard paste (`wl-paste`) with modal preview dialog and direct execution. |
| **Open in Konsole** | **Implemented** | One-click button to open detached Konsole in the active tab's working directory. |
| **Command History** | *In-Memory* | Maintained strictly in-memory per session (cleared on plasmoid restart). |
| **Global Shortcut** | **Automated** | Automatically registered during install via `org.kde.kglobalaccel` over D-Bus (`Meta+N`); manual System Settings fallback documented. |

---

## 💻 Requirements

* **KDE Plasma:** Tested on Plasma 6.8.2 (Linux x86_64, Wayland). Compatibility on earlier Plasma 6.x releases (e.g. 6.0) is untested.
* **Qt / Frameworks:** Qt 6.x, Kirigami 3 / KF6.
* **Wayland Clipboard Utility:** `wl-clipboard` (provides `wl-paste` for clipboard actions).
* **Terminal Emulator:** `konsole` (for external terminal launching).
* **D-Bus Scripting Tools:** `qt6-tools` or `qt5-tools` (provides `qdbus6` or `qdbus` for panel toggling).
* **System Monitoring:** `ksystemstats` (default in Plasma 6).
* **Recommended Fonts:** System default interface font (e.g. Inter, Noto Sans) and system monospace font for code.

---

## 📦 Installation & Setup

### Regular Installation (Plasma Package)

```bash
# Clone the repository
git clone https://github.com/BerKetKet/nevermore.git ~/projects/nevermore
cd ~/projects/nevermore

# Install or upgrade via kpackagetool6
./install.sh
```

### Developer Mode (Live Symlink)

```bash
# Symlink directly to local source tree
./install.sh --dev
```

### Uninstallation

```bash
# Remove plasmoid and helper files
./install.sh --uninstall
```

---

## ⌨️ Configuring the Global Shortcut (Meta + N)

`./install.sh` automatically registers the global shortcut `Meta+N` on KDE Plasma 6 Wayland via the `org.kde.kglobalaccel` D-Bus interface (`doRegister` and `setShortcutKeys`), binding it directly to `toggle-nevermore.desktop`.

If automated registration is skipped (e.g. headless installation or missing `python-gobject`), you can configure the shortcut manually in KDE System Settings:

1. Open **System Settings** -> **Keyboard** -> **Shortcuts**.
2. Locate **Toggle Nevermore Control Center** under Applications (or click **Add New** -> **Command or Script**).
3. If adding manually as a custom script, set the command to:
   ```bash
   ~/.local/bin/toggle-nevermore.sh
   ```
4. Click the shortcut button, press **`Meta + N`**, and click **Apply**.

---

## 🏃 Quick Run Command Runner Architecture

The **Run** tab provides an honest, reliable one-shot command runner (no fragile pseudo-terminal emulation):

* **Execution Helper (`scripts/nevermore-run`):** Commands are dispatched via a dedicated bash helper that accepts base64-encoded working directory and command strings alongside a random per-run sentinel token (validated against `^[A-Za-z0-9_]+$`). This eliminates shell-quoting hazards and makes accidental token collisions virtually impossible (though an untrusted command output that knew or guessed the token could forge completion lines). Stdin is redirected from `/dev/null`, and an inner `EXIT` trap guarantees accurate exit code and directory capture even if commands call `exit N`.
* **Process Group Isolation:** Commands run in isolated sessions via `setsid`. Clicking **Stop** sends `SIGTERM` followed by a grace period and `SIGKILL` to the entire process group (`-PGID`), preventing runaway child processes or orphaned tasks. Stop/PID-file race conditions are resolved via sentinel stop markers.
* **Exit Code Tracking:** Real process exit codes are captured. Zero indicates success, while non-zero exit codes are highlighted in red (`[Exit <code\>]`).
* **Timeout Handling:** Commands exceeding the 30-second timeout exit with status 124, displaying an informative hint and offering an immediate **Open in Konsole** button.
* **Background Tasks:** Long-running jobs can be launched as transient systemd user services (`systemd-run --user --remain-after-exit`). The Tasks panel queries `systemctl --user list-units "nevermore-task-*" --all --output=json` and inspects exit status via `systemctl --user show`. Running (`running`), completed (`done (0)`), and failed (`failed (N)`) tasks are displayed distinctly. Finished tasks can be dismissed (`systemctl --user stop` and `reset-failed`), and logs can be viewed at any time (`journalctl --user -u <unit> -n 200 --no-pager`).
* **Measured Polling Gating:** Background task polling is gated strictly to `(Run tab visible && Tasks expanded) || hasRunningTasks`. When tasks are actively running, polling occurs every 3 seconds; when idle, it relaxes to 5 seconds. Launching, stopping, or dismissing a task triggers an immediate single refresh.
* **Safe Paste:** Pasting from clipboard checks for newline characters; multiline snippets require confirmation in a truly modal preview dialog before execution.
* **In-Memory History:** Command logs and tab state are maintained in-memory for the duration of the Plasma session.

---

## ⚠️ Known Issues & Technical Notes

* **Disk Utilization Sensor:** Nevermore currently tracks aggregate filesystem utilization across all mounts via the sensor `disk/all/usedPercent` rather than partition-specific UUIDs, ensuring compatibility across differing partition setups.
* **Hardware Visibility & Panel Autohide:** Measurements on Plasma 6 Wayland confirmed that plasmoids embedded in panels report `Window.window` as `null` during regular embedded operation, and panel autohide translations do not toggle `QWindow` visibility state. Consequently, hardware sensor polling is gated strictly by component visibility (`hwRoot.visible`), pausing telemetry queries when navigating away from the Widgets tab.
* **Continuous Integration qmllint Scope:** Continuous Integration `qmllint` runs on headless Ubuntu runners where KF6 and Plasma QML modules are not installed in system paths; CI runs `qmllint` with unresolved type and missing property checks disabled (`--unresolved-type disable --missing-property disable`). In CI, `qmllint` acts as a syntax, scoping, and structural check rather than a complete type-system verification.
* **Command Persistence:** Command runner history is currently maintained in memory during the active session. If plasmashell restarts, command runner tabs and history reset to the default workspace.

---

## 🗺️ Roadmap

See [docs/ROADMAP.md](docs/ROADMAP.md) for detailed phase breakdowns and upcoming milestones.

---

## 📜 License

Licensed under the **GNU General Public License v3.0 or later** ([GPL-3.0-or-later](LICENSE)).
