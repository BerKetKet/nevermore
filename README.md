# 🦅 Nevermore Control Center

> *"Quoth the Raven, 'Nevermore.'"* — Edgar Allan Poe

**Nevermore** is an advanced, modular, and aesthetic slide-out **Control Center** for **KDE Plasma 6 (Wayland)**. Built to transcend the limitations of sparse desktop applets, Nevermore delivers a unified, high-density dashboard inspired by Budgie's *Raven* and macOS *Control Center*—engineered to be the definitive control center for KDE Plasma.

---

## 📊 Feature Status Matrix

| Feature | Status | Notes |
| :--- | :--- | :--- |
| **Segmented Tab Flyout** | **Implemented** | Three dedicated tabs: Widgets, Notifications, and Run. |
| **Single-Surface Architecture** | **Implemented** | Control center rendered strictly inside native zero-strut popup dialog (`PlasmaQuick::Dialog`). Zero desktop window shift. |
| **Edge Hover & Trigger** | **Implemented** | Right screen edge unhides panel; hovering compact icon (~150ms) expands popup (click toggles fallback). |
| **Interactive Calendar** | **Implemented** | Full 7x6 month grid with month navigation and current day highlight. |
| **Calendar Reminders & Tasks** | *Deferred* | Reminders and task synchronization held off pending future Google Calendar integration. |
| **Overall CPU Telemetry** | **Implemented** | Aggregate CPU load percentage via `org.kde.ksysguard.sensors`. |
| **Per-Core CPU Stats** | *Planned* | Per-core CPU load breakdown is scheduled for a future release. |
| **RAM Telemetry** | **Implemented** | Real-time memory consumption (`Used GB / Total GB`) and percentage. |
| **Storage Utilization** | **Implemented** | Aggregate storage utilization across mounted filesystems (`disk/all`). |
| **Network Throughput** | **Implemented** | Real-time aggregate upload and download throughput. |
| **MPRIS Media Controller** | **Implemented** | Multi-player switcher (`‹ Player Name (1/N) ›`), album art, track details, and playback controls. |
| **Audio Volume Controls** | **Implemented** | Master output and microphone volume sliders with toggle mute. |
| **Notification Center** | **Implemented** | Aggregated notification feed with Do Not Disturb and bulk clearing. |
| **Notification Actions** | *Partial* | Per-notification dismissal works; action buttons planned for Phase 5. |
| **Notification Timestamps**| *Planned* | Relative timestamps ("5m ago") scheduled for Phase 5. |
| **Expandable Notifications**| *Planned* | Collapsible long-body notification cards scheduled for Phase 5. |
| **Quick Run Tab** | **Implemented** | Inline blinking-cursor terminal prompt inside buffer (no bottom bar), exit codes, directory tracking, and process group control. |
| **Process Group Termination** | **Implemented** | Stop button terminates entire process group using `setsid` and `kill -TERM` then `kill -KILL`. |
| **Background Tasks** | **Implemented** | Launch, list (`--output=json`), inspect logs, stop active units, and dismiss finished/failed units (`nevermore-task-*`). |
| **Multiline Paste Protection**| **Implemented** | Clipboard paste (`wl-paste`) with modal preview dialog and direct execution. |
| **Open in Konsole** | **Implemented** | One-click button to open detached Konsole in the active tab's working directory. |
| **Command History** | *In-Memory* | Maintained strictly in-memory per session (cleared on plasmoid restart). |
| **Global Shortcut** | **Native** | Native Plasma widget shortcut (`Meta+N`) toggles popup dialog without window shifts (0px shift). |

---

## 💻 Requirements

* **KDE Plasma:** Tested on Plasma 6.8.2 (Linux x86_64, Wayland). Compatibility on earlier Plasma 6.x releases (e.g. 6.0) is untested.
* **Qt / Frameworks:** Qt 6.x, Kirigami 3 / KF6.
* **Wayland Clipboard Utility:** `wl-clipboard` (provides `wl-paste` for clipboard actions).
* **Terminal Emulator:** `konsole` (for external terminal launching).
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

### Reloading Plasma Shell (Optional)

To flush Plasma's QML bytecode cache and reload plasmashell after updating:

```bash
./install.sh --restart-shell
```

---

## 📐 Panel Setup & Edge Geometry

Nevermore renders exclusively inside a native Plasma popup dialog (`PlasmaQuick::Dialog`). Under KDE Plasma 6, popup dialogs anchor directly against the inner boundary of the parent panel.

If your right panel has excess thickness (for instance, a panel set to 380 px from a legacy full-width sidebar configuration), the popup dialog will sit 380 px inwards from the monitor bezel, leaving a wide void between the dialog and screen edge.

### Recommended Panel Configuration
For a clean slide-out edge aesthetic, place Nevermore in a thin autohide edge panel:
* **Recommended Thickness:** `36 px` to `48 px` (default `40 px`).
* **Hiding Mode:** `Auto Hide` (reveals when hovering the screen edge).
* **Length:** Custom or Fit Content.

### Setting Up the Panel in Edit Mode
1. Right-click the desktop background or any existing panel and choose **Enter Edit Mode** (or press `Meta+D, E`).
2. If configuring an existing right-edge panel:
   * Click on the right panel to display its configuration toolbar.
   * Drag the **Thickness** slider to adjust thickness to **`40 px`** (recommended 36–48 px).
   * Under **Visibility**, select **Auto Hide**.
3. If creating a new right-edge panel:
   * In Edit Mode, click **Add Panel** -> **Empty Panel**.
   * Drag the panel to the right screen edge.
   * Set thickness to **`40 px`** and visibility to **Auto Hide**.
   * Click **Add Widgets...**, search for **Nevermore**, and drag it into the panel.
4. Click **Close** or press `Escape` to exit Edit Mode.

With this setup, moving your mouse cursor to the right screen edge reveals the thin panel; hovering the Nevermore icon expands the full dashboard flush against the right edge.

---

## ⌨️ Configuring the Global Shortcut (Meta + N)

Nevermore leverages KDE Plasma's native widget shortcut mechanism:

1. Right-click the **Nevermore** icon in your right panel (or top panel).
2. Select **Configure Nevermore...** (or press `Alt+D, S`).
3. In the settings dialog, click **Keyboard Shortcuts**.
4. Set the shortcut to **`Meta + N`** and click **Apply**.

Once configured, pressing `Meta+N` natively toggles the popup dialog (`expanded` state). Because the dialog renders as a floating popup surface rather than a strutted panel surface, existing desktop and tiled windows do not shift or resize (0px shift).

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

* **Single-Surface Architecture:** In KDE Plasma 6 Wayland, panels are strutted layer-shell surfaces whose keyboard interactivity defaults to None. Nevermore addresses this by rendering exclusively within Plasma's native floating dialog (`PlasmaQuick::Dialog`), providing full physical keyboard input and zero desktop window shift across both `Meta+N` and edge hover activation.
* **Disk Utilization Sensor:** Nevermore currently tracks aggregate filesystem utilization across all mounts via the sensor `disk/all/usedPercent` rather than partition-specific UUIDs, ensuring compatibility across differing partition setups.
* **Hardware Visibility & Panel Autohide:** Measurements on Plasma 6 Wayland confirmed that plasmoids embedded in panels report `Window.window` as `null` during regular embedded operation, and panel autohide translations do not toggle `QWindow` visibility state. Consequently, hardware sensor polling is gated strictly by component visibility (`hwRoot.visible`), pausing telemetry queries when navigating away from the Widgets tab.
* **Continuous Integration qmllint Scope:** Continuous Integration `qmllint` runs on headless Ubuntu runners where KF6 and Plasma QML modules are not installed in system paths; CI runs `qmllint` with unresolved type and missing property checks disabled (`--import disable --unresolved-type disable --missing-property disable --unqualified disable`). In CI, `qmllint` acts as a syntax, scoping, and structural check rather than a complete type-system verification.
* **Command Persistence:** Command runner history is currently maintained in memory during the active session. If plasmashell restarts, command runner tabs and history reset to the default workspace.

---

## 🗺️ Roadmap

See [docs/ROADMAP.md](docs/ROADMAP.md) for detailed phase breakdowns and upcoming milestones.

---

## 📜 License

Licensed under the **GNU General Public License v3.0 or later** ([GPL-3.0-or-later](LICENSE)).
