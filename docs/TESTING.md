# 🧪 Nevermore Control Center — Manual Smoke Test Checklist

This document provides a manual verification checklist for human QA and testers on KDE Plasma 6 (Wayland). It covers single-surface behavior, interactive widgets, notification click-through and raising fallback, managed terminal window controls, tiling isolation, and background task operations.

---

## 🛠️ Pre-flight & Setup Instructions

1. **Clone & Install:**
   ```bash
   git clone https://github.com/BerKetKet/nevermore.git ~/projects/nevermore
   cd ~/projects/nevermore
   ./install.sh --dev --krohnkite-rule
   ```
2. **Panel Setup (Right Edge):**
   - Place Nevermore in a thin autohide panel on the right edge (recommended thickness: 24 px).
   - In Edit Mode: set thickness to 24 px and visibility to **Auto Hide**.
3. **Configure Global Shortcuts:**
   - **Popup Control Center:** Right-click Nevermore -> **Configure Nevermore...** -> **Keyboard Shortcuts** -> `Meta+N`.
   - **Managed Terminal:** `Meta+Shift+N` (or run `nevermore-term toggle`).

---

## 📋 Smoke Test Plan

| ID | Feature | Test Steps | Expected Behavior |
| :--- | :--- | :--- | :--- |
| **T01** | **Single Instance Verification** | Query Plasma Shell panel applets via D-Bus script. | Exactly one instance of `io.github.berketket.nevermore` exists across all panels (residing in the right autohide panel). |
| **T02** | **Edge Hover & 150ms Trigger** | Move mouse cursor to right screen edge to reveal autohide panel, then hover the Nevermore compact icon for ~150ms. | Hovering unhides panel; after 150ms hover delay, the full control center popup dialog expands. Clicking the icon immediately toggles expansion. |
| **T03** | **Global Shortcut Toggle (Meta+N)** | Press `Meta+N` on the physical keyboard. | The Nevermore control center popup dialog toggles open/closed via native `activationTogglesExpanded`. |
| **T04** | **Surface & Visual Identity** | Open via edge hover, observe UI. Close and open via `Meta+N`. | Both activation methods display the exact same floating popup dialog (`PlasmaQuick::Dialog`). No dual representation or styling divergence. |
| **T05** | **Zero-Strut Window Geometry** | Open a window (e.g. Chrome or terminal) adjacent to the right edge. Press `Meta+N`. | The popup appears as a floating overlay above the window. Open windows do NOT shift, resize, or reflow (0px shift). |
| **T06** | **Tab Navigation** | Click on the **Widgets**, **Notifications**, and **Terminal** header tabs. | Active tab switches immediately. Segmented control background highlight follows selection. |
| **T07** | **Interactive Calendar** | 1. View Calendar widget.<br>2. Click **<** and **>** month arrows.<br>3. Click **Today** button. | Current date is highlighted in blue. Month navigation transitions accurately. Clicking "Today" snaps back to the current month. |
| **T08** | **Hardware Telemetry** | Observe CPU, RAM, Disk, and Network gauges on the Widgets tab. | Telemetry reflects real system utilization. Values update smoothly. Polling pauses when switching away to another tab. |
| **T09** | **Media Controls & Multi-Player Switcher** | 1. Start media in two players.<br>2. Observe multi-player switcher header (`‹ Player Name (1/2) ›`).<br>3. Click `‹` and `›` to cycle active players.<br>4. Observe track title, artist, album art, play/pause. | Switcher displays active player identity and count. Cycling immediately updates active track and controls. Controls disable gracefully when no media player is active. |
| **T10** | **Volume & Audio Sliders** | 1. Drag Master Volume slider.<br>2. Click Mute icon.<br>3. Drag Microphone Volume slider. | Audio volume changes smoothly with drag. Mute icon toggles mute state. Sliders disable gracefully if audio sink/source is absent. |
| **T11** | **Notification Feed** | Trigger a notification (`notify-send "Test" "Sample notification"`). Switch to **Notifications** tab. | Notification appears in list with summary and body. Badge counter on Notifications tab increments. |
| **T12** | **Notification Action Click-Through** | Trigger notification with action (`notify-send -A default=Open "Alert" "Body"`). Click card body. | Default action executes, notification closes, and Nevermore collapses (`root.expanded = false`). |
| **T13** | **Notification Dismiss Isolation** | Click the **✕** button on an action-enabled notification. | Notification is dismissed without triggering the default action. Nevermore remains open. |
| **T14** | **App Raising Fallback** | Trigger notification from open app without actions (`notify-send -h string:desktop-entry:google-chrome "Title" "Body"`). Click card body. | `nevermore-raise` unminimizes and activates the app's window, and Nevermore collapses. |
| **T15** | **Do Not Disturb & Clear All**| 1. Toggle **Do Not Disturb** switch.<br>2. Click **Clear All** button. | DND toggles notification server inhibition. "Clear All" dismisses all notifications and clears list without activating card actions. |
| **T16** | **Terminal Tab — Show/Hide Toggle** | 1. Navigate to **Terminal** tab.<br>2. Click **Show Terminal** button.<br>3. Observe status indicator change to Active and button change to **Hide Terminal**.<br>4. Click **Hide Terminal**. | Konsole window docks flush to right edge (397px, full height, noBorder). Status updates to Running (active) / Minimized. |
| **T17** | **Terminal Window Attributes** | Query KWin window attributes of managed terminal window via `nevermore-term status` or D-Bus. | Window possesses `keepAbove: 1`, `skipTaskbar: 1`, `skipPager: 1`, `skipSwitcher: 1`, `noBorder: 1`, `minimized: 0`. |
| **T18** | **Tiling Isolation (Krohnkite)** | With Chrome open, toggle managed terminal multiple times (`nevermore-term toggle`). | Chrome window maintains identical geometry (`0,24 1920x1052`) before, during, and after terminal display. No window shift or resize occurs. |
| **T19** | **Terminal Keyboard Fidelity** | Show managed terminal and type commands (`htop`, `vim`, shell aliases). | 100% native Konsole keyboard routing, shortcuts, copy/paste, and shell functionality operate with zero lag or missing keys. |
| **T20** | **Process Lifecycle Recovery** | 1. Open managed terminal.<br>2. In the terminal, type `exit` to close it.<br>3. In the Terminal tab, click **Show Terminal** or press `Meta+Shift+N`. | Process death is detected cleanly (`nevermore-term status` shows `stopped`), and the next toggle launches a fresh instance. |
| **T21** | **Background Tasks — Launch** | In the Terminal tab, enter `sleep 10` in the task input box and click **Launch**. | Task is submitted via `nevermore-run` as a transient systemd user service (`nevermore-task-*`). Task appears in list with `RUNNING` badge. |
| **T22** | **Background Tasks — Completion & Exit Code** | Enter `true` and launch. Then enter `false` and launch. | Succeeding task transitions to `EXIT 0` with gray badge. Failing task transitions to `FAILED` with red badge. |
| **T23** | **Background Tasks — Logs** | Click **Logs** button next to any task. | Journal logs for the unit (`journalctl --user -u ...`) load into scrollable viewer. |
| **T24** | **Background Tasks — Stop** | Launch `sleep 60`. While running, click **Stop**. | Unit is stopped immediately via `systemctl --user stop`. |
| **T25** | **Background Tasks — Dismiss & Clear Finished**| Click **Dismiss** on an exited task, or click **Clear Finished**. | Exited/failed units are stopped and reset (`systemctl --user reset-failed`), removing them from the list. |

---

## 📝 Tester Results Template

Copy and fill this table for test reports:

| Feature | Steps | Expected | Result (Pass/Fail) | Notes |
| :--- | :--- | :--- | :--- | :--- |
| **T01: Single Instance** | Query D-Bus panel applets | 1 instance | | |
| **T02: Edge Hover & 150ms Trigger**| Hover right edge & icon | Popup expands | | |
| **T03: Global Shortcut (Meta+N)** | Press `Meta+N` | Popup toggles | | |
| **T04: Surface Identity** | Compare hover vs Meta+N | Identical popup | | |
| **T05: Zero-Strut Geometry** | Open window, toggle popup | 0px window shift | | |
| **T06: Tab Switching** | Click Widgets / Notifications / Terminal | Switched view | | |
| **T07: Calendar Grid** | Navigate months, click Today | Correct dates | | |
| **T08: Hardware Telemetry** | Check CPU, RAM, Disk, Net | Live gauges | | |
| **T09: Media Controls** | Play/pause external music | Controls work | | |
| **T10: Volume Sliders** | Drag master/mic sliders, mute | Audio adjusts | | |
| **T11: Notifications Feed**| Send notification, check tab | Card displayed | | |
| **T12: Notification Action Click**| Click action-enabled card | Action runs | | |
| **T13: Notification Dismiss** | Dismiss single notification | Card removed | | |
| **T14: App Raising Fallback** | Click non-action card | App raised | | |
| **T15: DND & Clear All** | Toggle DND, Clear All | Feed cleared | | |
| **T16: Terminal Show/Hide** | Click Show/Hide Terminal | Terminal slides | | |
| **T17: Window Attributes** | Query KWin window attributes | Utility/keepAbove | | |
| **T18: Tiling Isolation** | Check Chrome geom before/during/after | 0px shift | | |
| **T19: Terminal Fidelity** | Run interactive CLI tools | 100% native | | |
| **T20: Lifecycle Recovery**| Type `exit`, toggle again | Restarts clean | | |
| **T21: Task Launch** | Launch `sleep 10` | Task `RUNNING` | | |
| **T22: Task Exit Code** | Launch `true` / `false` | `EXIT 0` / `FAILED` | | |
| **T23: Task Logs** | Click Logs on task | Journal shown | | |
| **T24: Task Stop** | Stop running task | Task halted | | |
| **T25: Task Dismiss** | Dismiss finished task | Cleared from list | | |
