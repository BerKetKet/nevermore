# 🧪 Nevermore Control Center — Manual Smoke Test Checklist

This document provides a 10-minute manual verification script for human QA and testers on KDE Plasma 6 (Wayland). It walks through a clean setup, verifying all interactive control center capabilities, single-surface architecture, edge cases, and safety mechanisms.

---

## 🛠️ Pre-flight & Setup Instructions

1. **Clone & Install:**
   ```bash
   git clone https://github.com/BerKetKet/nevermore.git ~/projects/nevermore
   cd ~/projects/nevermore
   ./install.sh --dev
   ```
2. **Panel Setup (Right Edge):**
   - Ensure you have a thin autohide panel on the right edge (recommended thickness: 36–48 px, default 40 px).
   - If adjusting an existing panel: Right-click desktop -> **Enter Edit Mode** -> click right panel -> set thickness to 40 px and visibility to **Auto Hide** -> press `Escape`.
3. **Add Widget to Right Edge Panel:**
   - In Edit Mode or by right-clicking the panel: **Add Widgets...** -> drag **Nevermore** onto the right-edge panel.
4. **Configure Global Shortcut (Meta + N):**
   - Right-click the Nevermore icon -> **Configure Nevermore...** -> **Keyboard Shortcuts**.
   - Set shortcut to `Meta+N` and click **Apply**.

---

## 📋 Smoke Test Plan

| ID | Feature | Test Steps | Expected Behavior |
| :--- | :--- | :--- | :--- |
| **T01** | **Single Instance Verification** | Query Plasma Shell panel applets via D-Bus script. | Exactly one instance of `io.github.berketket.nevermore` exists across all panels (residing in the right autohide panel). |
| **T02** | **Edge Hover & 150ms Trigger** | Move mouse cursor to right screen edge to reveal autohide panel, then hover the Nevermore compact icon for ~150ms. | Hovering unhides panel; after 150ms hover delay, the full control center popup dialog expands. Clicking the icon immediately toggles expansion. |
| **T03** | **Global Shortcut Toggle** | Press `Meta+N` on the physical keyboard. | The Nevermore control center popup dialog toggles open/closed via native `activationTogglesExpanded`. |
| **T04** | **Surface & Visual Identity** | Open via edge hover, observe UI. Close and open via `Meta+N`. | Both activation methods display the exact same floating popup dialog (`PlasmaQuick::Dialog`). No dual representation or styling divergence. |
| **T05** | **Zero-Strut Window Geometry** | Open a window (e.g. Chrome or terminal) adjacent to the right edge. Press `Meta+N`. | The popup appears as a floating overlay above the window. Open windows do NOT shift, resize, or reflow (0px shift). |
| **T06** | **Popup Keyboard Interactivity** | Open Nevermore via `Meta+N` or edge hover, navigate to **Run** tab, and type directly on the keyboard. | Physical keystrokes are routed immediately to the inline terminal prompt without requiring manual focus workarounds. |
| **T07** | **Tab Navigation** | Click on the **Widgets**, **Notifications**, and **Run** header tabs. | Active tab switches immediately. Segmented control background highlight follows selection. |
| **T08** | **Interactive Calendar** | 1. View Calendar widget.<br>2. Click **<** and **>** month arrows.<br>3. Click **Today** button. | Current date is highlighted in blue. Month navigation transitions accurately. Clicking "Today" snaps back to the current month. |
| **T09** | **Hardware Telemetry** | Observe CPU, RAM, Disk, and Network gauges on the Widgets tab. | Telemetry reflects real system utilization. Values update smoothly. Polling pauses when switching away to another tab. |
| **T10** | **Media Controls & Multi-Player Switcher** | 1. Start media in two players (e.g. Spotify, browser).<br>2. Observe multi-player switcher header (`‹ Player Name (1/2) ›`).<br>3. Click `‹` and `›` to cycle active players.<br>4. Observe track title, artist, album art, play/pause. | Switcher displays active player identity and count. Cycling immediately updates active track and controls. Controls disable gracefully when no media player is active. |
| **T11** | **Volume & Audio Sliders** | 1. Drag Master Volume slider.<br>2. Click Mute icon.<br>3. Drag Microphone Volume slider. | Audio volume changes smoothly with drag. Mute icon toggles mute state. Sliders disable gracefully if audio sink/source is absent. |
| **T12** | **Notification Feed** | Trigger a notification (e.g. `notify-send "Test" "Sample notification"`). Switch to **Notifications** tab. | Notification appears in list with summary and body. Badge counter on Notifications tab increments. |
| **T13** | **Notification Action Click-Through** | Trigger notification with action (`notify-send -A default=Open "Alert" "Body"`). Click card body. | Default action executes (client prints `default`), notification closes, and Nevermore collapses (`root.expanded = false`). |
| **T14** | **Notification Dismiss Isolation** | Click the **✕** button on an action-enabled notification. | Notification is dismissed without triggering the default action. Nevermore remains open. |
| **T15** | **App Raising Fallback** | Trigger notification from open app without actions (`notify-send -h string:desktop-entry:google-chrome "Title" "Body"`). Click card body. | KWin activates the app's window and Nevermore collapses. |
| **T16** | **Do Not Disturb & Clear All**| 1. Toggle **Do Not Disturb** switch.<br>2. Click **Clear All** button. | DND toggles notification server inhibition. "Clear All" dismisses all notifications and clears list without activating card actions. |
| **T15** | **Quick Run Inline Blinking Prompt** | 1. Switch to **Run** tab.<br>2. Observe inline green prompt (`~/path ❯ `) inside terminal buffer with blinking block cursor (█).<br>3. Click empty terminal space to verify active focus.<br>4. Type `echo "Nevermore Hello"` and press Enter. | Command executes, prompt hides during execution, output displays `Nevermore Hello` followed by checkmark, and inline prompt refocuses. |
| **T16** | **Directory Tracking** | Type `cd /tmp` and press Enter. Then run `pwd`. | Working directory persists across commands; prompt displays `/tmp ❯`, `pwd` outputs `/tmp`. |
| **T17** | **Exit Code Display** | 1. Run `true`.<br>2. Run `false` or `bash -c 'exit 42'`. | Success (`true`) displays green indicator. Failure displays red `[Exit 42]` badge. |
| **T18** | **Process Group Stop** | 1. Run `sleep 30`.<br>2. While running, click the **Stop** button. | Command execution halts immediately; output indicates `[Terminated by user]`; UI returns to ready state. |
| **T19** | **Timeout Handling** | Run a command exceeding 30s without stopping it. | At 30s, command is terminated with exit code 124, timeout warning, and an "Open in Konsole" suggestion. |
| **T20** | **Paste & Multiline Safety** | 1. Single-line clipboard: Click **Paste**.<br>2. Multi-line clipboard: Click **Paste**. | Single-line inserts into inlineInput and focuses. Multi-line triggers modal preview dialog; **Cancel** aborts, **Run** executes safely. |
| **T21** | **Open in Konsole** | Click the **Open in Konsole** button in the header. | A standalone Konsole window opens detached in the active tab's current working directory. Repeating opens another independent window. |
| **T22** | **Terminal Tabs** | 1. Click **+** to add a new tab.<br>2. Switch between Tab 1 and Tab 2.<br>3. Close Tab 2. | New tab initializes with independent history and directory. Switching preserves buffer contents. Closing removes tab. |
| **T23** | **Background Tasks — Success** | Run a fast task in background. Expand **Tasks** collapsible. | Unit appears in Tasks list, state transitions from `running` to `done (0)`. Clicking **Logs** shows journalctl output. |
| **T24** | **Background Tasks — Failure** | Run `false` or `exit 1` in background. Expand **Tasks**. | Unit displays distinct red `failed (1)` badge. Clicking **Logs** shows failure trace. Clicking **Dismiss** clears the unit. |
| **T25** | **Background Tasks — Stop** | Run `sleep 60` in background. Expand **Tasks**. | Unit shows green `running` badge with **Stop** button. Clicking **Stop** halts unit immediately and removes it from running list. |

---

## 📝 Tester Results Template

Copy and fill this table for test reports:

| Feature | Steps | Expected | Result (Pass/Fail) | Notes |
| :--- | :--- | :--- | :--- | :--- |
| **T01: Single Instance** | Query D-Bus panel applets | 1 instance | | |
| **T02: Edge Hover & 150ms Trigger**| Hover right edge & icon | Popup expands | | |
| **T03: Global Shortcut** | Press `Meta+N` | Popup toggles | | |
| **T04: Surface Identity** | Compare hover vs Meta+N | Identical popup | | |
| **T05: Zero-Strut Geometry** | Open window, toggle popup | 0px window shift | | |
| **T06: Keyboard Interactivity** | Type in Run tab | Keystrokes work | | |
| **T07: Tab Switching** | Click Widgets / Notifications / Run | Switched view | | |
| **T08: Calendar Grid** | Navigate months, click Today | Correct dates | | |
| **T09: Hardware Telemetry** | Check CPU, RAM, Disk, Net | Live gauges | | |
| **T10: Media Controls** | Play/pause external music | Controls work | | |
| **T11: Volume Sliders** | Drag master/mic sliders, mute | Audio adjusts | | |
| **T12: Notifications Feed**| Send notification, check tab | Card displayed | | |
| **T13: Notification Dismiss** | Dismiss single notification | Card removed | | |
| **T14: DND & Clear All** | Toggle DND, Clear All | Feed cleared | | |
| **T15: Command Execution** | Run `echo test` in Run tab | Output shown | | |
| **T16: Directory Tracking**| Run `cd /tmp && pwd` | CWD tracked | | |
| **T17: Exit Code Display**| Run `exit 42` | Red `[Exit 42]` | | |
| **T18: Process Group Stop**| Run `sleep 30`, click Stop | Terminated | | |
| **T19: Command Timeout** | Let command run > 30s | Exit 124 hint | | |
| **T20: Multiline Paste** | Paste multi-line script | Modal dialog | | |
| **T21: Open in Konsole** | Click Konsole button | Konsole opens | | |
| **T22: Terminal Tabs** | Add/switch/close tabs | Independent | | |
| **T23: Tasks (Success)** | Run `--bg` succeeding command | `done (0)` | | |
| **T24: Tasks (Failure)** | Run `--bg false` | `failed (1)` | | |
| **T25: Tasks (Stop)** | Run `--bg sleep 60`, click Stop | Unit stopped | | |
