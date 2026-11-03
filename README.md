# 🦅 Nevermore Control Center

> *"Quoth the Raven, 'Nevermore.'"* — Edgar Allan Poe

**Nevermore** is an advanced, modular, and aesthetic slide-out **Control Center** for **KDE Plasma 6 (Wayland)**. Built to transcend the limitations of sparse desktop applets, Nevermore delivers a unified, high-density dashboard inspired by Budgie's *Raven* and macOS *Control Center*—engineered to be the definitive control center for KDE Plasma.

---

## 📊 Feature Status Matrix

| Feature | Status | Notes |
| :--- | :--- | :--- |
| **Segmented Tab Flyout** | **Implemented** | Three dedicated tabs: Widgets, Notifications, and Terminal. |
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
| **Notification Click-Through** | **Implemented** | Default action invoked via model; non-action notifications raise the app window via `nevermore-raise`. |
| **Managed Terminal Window** | **Implemented** | Dedicated Konsole terminal window managed at the right edge (`397px` width, full height, `keepAbove`, `skipTaskbar`, `skipPager`, `skipSwitcher`, `noBorder`). |
| **Tiling Isolation (Krohnkite)** | **Implemented** | Terminal window is utility-classed and excluded from tiling managers via KWin window rule and Krohnkite configuration. Zero window resize/shift. |
| **Background Tasks** | **Implemented** | Single-line task launcher (`systemd-run --user`), list (`--output=json`), log viewer (`journalctl`), stop, and dismiss. |
| **Global Shortcuts** | **Native** | `Meta+N` toggles the popup control center; `Meta+Shift+N` (or `nevermore-term toggle`) toggles the managed terminal. |

---

## 💻 Requirements

* **KDE Plasma:** Tested on Plasma 6.8.2 (Linux x86_64, Wayland).
* **Qt / Frameworks:** Qt 6.x, Kirigami 3 / KF6, Plasma5Support.
* **Terminal Emulator:** `konsole` (default, configurable via `~/.config/nevermore/terminal.conf`).
* **System Monitoring:** `ksystemstats` (default in Plasma 6).
* **Process Management:** `systemd` user session (`systemctl --user`, `journalctl --user`).

---

## 📦 Installation & Setup

### Regular Installation (Plasma Package)

```bash
# Clone the repository
git clone https://github.com/BerKetKet/nevermore.git ~/projects/nevermore
cd ~/projects/nevermore

# Install or upgrade via kpackagetool6 with terminal helpers and window rules
./install.sh --krohnkite-rule
```

### Developer Mode (Live Symlink)

```bash
# Symlink directly to local source tree
./install.sh --dev --krohnkite-rule
```

### Optional Managed Terminal Autostart

To automatically start the managed terminal in the background (minimized) on desktop login:

```bash
./install.sh --autostart-terminal
```

### Uninstallation

```bash
# Cleanly remove plasmoid, helpers, desktop entries, rules, and autostart
./install.sh --uninstall
```

### Reloading Plasma Shell (Optional)

To flush Plasma's QML bytecode cache and reload plasmashell after updating:

```bash
./install.sh --restart-shell
```

---

## 📐 Panel Setup & Edge Geometry

Nevermore renders exclusively inside a native Plasma popup dialog (`PlasmaQuick::Dialog`). Under KDE Plasma 6 Wayland, popup dialogs anchor directly against the inner boundary of the parent panel.

For a clean slide-out edge aesthetic flush with your monitor bezel:
* **Recommended Thickness:** `24 px` to `36 px` (Plasma 6 minimum thickness is 24 px).
* **Hiding Mode:** `Auto Hide` (reveals when hovering the screen edge).
* **Length:** Full edge length (Fill) or custom.

### Setting Up the Panel in Edit Mode
1. Right-click the desktop background or any existing panel and choose **Enter Edit Mode** (or press `Meta+D, E`).
2. If configuring an existing right-edge panel:
   * Click on the right panel to display its configuration toolbar.
   * Drag the **Thickness** slider to adjust thickness to **`24 px`** (or thinnest working value).
   * Under **Visibility**, select **Auto Hide**.
3. If creating a new right-edge panel:
   * In Edit Mode, click **Add Panel** -> **Empty Panel**.
   * Drag the panel to the right screen edge.
   * Set thickness to **`24 px`** and visibility to **Auto Hide**.
   * Click **Add Widgets...**, search for **Nevermore**, and drag it into the panel.
4. Click **Close** or press `Escape` to exit Edit Mode.

With this setup, moving your mouse cursor to the right screen edge reveals the thin panel; hovering the Nevermore icon expands the full dashboard flush against the right edge (24 px gap).

---

## 🖥️ Managed Terminal Window Architecture

Rather than fragile pseudo-terminal emulation or embedded widgets that lose native terminal capabilities, Nevermore manages a full, native terminal emulator window (Konsole) docked flush against the right screen edge:

* **Management Helper (`scripts/nevermore-term`):**
  - Subcommands: `toggle`, `show`, `hide`, `status`, `start-minimized`.
  - Process identification: Matches windows strictly by process ID (`$!`), not by window class.
  - Geometry & Placement: Automatically docks the window at the right edge (`397 px` width, full available screen height) via KWin ECMAScript.
  - Window Attributes: Enforces `keepAbove = true`, `skipTaskbar = true`, `skipPager = true`, `skipSwitcher = true`, `noBorder = true`, and `tile = null`.
* **Krohnkite & Tiling Isolation:**
  - Configures a KWin window rule forcing window type 16 (Utility) and exclusion from tiling.
  - Adds `ignoreClass=io.github.berketket.nevermore.terminal` to Krohnkite configuration.
  - Tested and proven: Chrome and other tiled windows experience **0 px shift or resize** when showing, hiding, or toggling the terminal.
* **Custom Terminal Configuration (`~/.config/nevermore/terminal.conf`):**
  - Default: `konsole --separate --desktopfile io.github.berketket.nevermore.terminal --profile Nevermore --hide-menubar --hide-tabbar`.
  - Optional custom emulator: Set `TERMINAL_COMMAND="custom_term -arg1 -arg2"`. Missing executables report a readable error.
* **Konsole Profile (`profiles/Nevermore.profile`):**
  - Enforces a fixed, non-overridable tab title `Nevermore`.
  - Hides menubar, tabbar, and terminal size hints for a sleek macOS/Budgie aesthetic.

---

## ⚙️ Background Tasks (`nevermore-run`)

The **Terminal** tab includes a built-in background task management center:

* **Task Launcher:** Single-line command box in the Terminal tab launches commands as transient systemd user services (`systemd-run --user --remain-after-exit`).
* **Task State Tracking:** Queries `systemctl --user list-units "nevermore-task-*" --all --output=json` and inspects exit codes via `systemctl --user show`.
* **State Visualization:** Tasks display distinct status badges (`RUNNING`, `EXIT 0`, `FAILED`).
* **Live Logs:** Clicking **Logs** loads output from `journalctl --user -u <unit> -n 200 --no-pager` in a scrollable viewer.
* **Stop & Dismiss:** Active tasks can be halted with **Stop** (`systemctl --user stop`). Finished tasks can be dismissed individually or cleared all at once.

---

## ⌨️ Global Shortcuts

* **`Meta + N` (Control Center Popup):**
  Configured via Right-click Nevermore -> **Configure Nevermore...** -> **Keyboard Shortcuts** -> `Meta+N`. Natively toggles the popup dialog (`expanded` state) with zero window shift.
* **`Meta + Shift + N` (Managed Terminal Window):**
  Desktop shortcut wired to `nevermore-term toggle`. Toggles the slide-out terminal window docked at the right edge.

---

## 🗺️ Roadmap

See [docs/ROADMAP.md](docs/ROADMAP.md) for detailed phase breakdowns and upcoming milestones.

---

## 📜 License

Licensed under the **GNU General Public License v3.0 or later** ([GPL-3.0-or-later](LICENSE)).
