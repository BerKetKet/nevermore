# 🧪 Nevermore Control Center — Manual Smoke Test Checklist

This document provides a 10-minute manual verification script for human QA and testers on KDE Plasma 6 (Wayland). It walks through a clean setup, verifying all interactive control center capabilities, edge cases, and safety mechanisms.

---

## 🛠️ Pre-flight & Setup Instructions

1. **Clone & Install:**
   ```bash
   git clone https://github.com/BerKetKet/nevermore.git ~/projects/nevermore
   cd ~/projects/nevermore
   ./install.sh --dev
   ```
2. **Add Widget to Desktop or Panel:**
   - Right-click your desktop or panel -> **Add Widgets...**
   - Search for **Nevermore** and drag it to your panel or desktop.
   - Alternatively, use the slide-out sidebar toggle script:
     ```bash
     ~/.local/bin/toggle-nevermore.sh
     ```

---

## 📋 Smoke Test Plan

| ID | Feature | Test Steps | Expected Behavior |
| :--- | :--- | :--- | :--- |
| **T01** | **Global Shortcut / Toggle** | Press `Meta+N` on the keyboard. | The Nevermore control center panel slides out or toggles visibility cleanly. Pressing `Meta+N` again closes it. |
| **T02** | **CLI Toggle Helper** | In a terminal, run `~/.local/bin/toggle-nevermore.sh`. | Outputs toggled state message; panel toggles without error. |
| **T03** | **Tab Navigation** | Click on the **Widgets**, **Notifications**, and **Run** header tabs. | Active tab switches immediately. Segmented control background highlight follows selection. |
| **T04** | **Interactive Calendar** | 1. View Calendar widget.<br>2. Click **<** and **>** month arrows.<br>3. Click **Today** button. | Current date is highlighted in blue. Month navigation transitions accurately. Clicking "Today" snaps back to the current month. |
| **T05** | **Hardware Telemetry** | Observe CPU, RAM, Disk, and Network gauges on the Widgets tab. | Telemetry reflects real system utilization. Values update smoothly. Polling pauses when switching away to another tab. |
| **T06** | **Media Controls** | 1. Start media in a supported player (e.g. Spotify, browser).<br>2. Observe track title, artist, album art.<br>3. Click Play/Pause, Next, Prev. | Track metadata renders accurately. Play/pause toggles playback. Controls disable gracefully when no media player is active. |
| **T07** | **Volume & Audio Sliders** | 1. Drag Master Volume slider.<br>2. Click Mute icon.<br>3. Drag Microphone Volume slider. | Audio volume changes smoothly with drag. Mute icon toggles mute state. Sliders disable gracefully if audio sink/source is absent. |
| **T08** | **Notification Feed** | Trigger a notification (e.g. `notify-send "Test" "Sample notification"`). Switch to **Notifications** tab. | Notification appears in list with summary and body. Badge counter on Notifications tab increments. |
| **T09** | **Notification Dismissal** | Click the close button on an individual notification card. | Specific notification is dismissed from list and counter updates. |
| **T10** | **Do Not Disturb & Clear All**| 1. Toggle **Do Not Disturb** switch.<br>2. Click **Clear All** button. | DND toggles notification server inhibition. "Clear All" dismisses all notifications and clears list. |
| **T11** | **Quick Run Execution** | 1. Switch to **Run** tab.<br>2. Type `echo "Nevermore Hello"` and press Enter. | Command executes, prompt shows formatted path (`❯`), output displays `Nevermore Hello`, followed by success checkmark. |
| **T12** | **Directory Tracking** | Type `cd /tmp` and press Enter. Then run `pwd`. | Working directory persists across commands; prompt displays `/tmp ❯`, `pwd` outputs `/tmp`. |
| **T13** | **Exit Code Display** | 1. Run `true`.<br>2. Run `false` or `bash -c 'exit 42'`. | Success (`true`) displays green indicator. Failure displays red `[Exit 42]` badge. |
| **T14** | **Process Group Stop** | 1. Run `sleep 30`.<br>2. While running, click the **Stop** button. | Command execution halts immediately; output indicates `[Terminated by user]`; UI returns to ready state. |
| **T15** | **Timeout Handling** | Run a command exceeding 30s without stopping it. | At 30s, command is terminated with exit code 124, timeout warning, and an "Open in Konsole" suggestion. |
| **T16** | **Multiline Paste Safety** | Copy a 3-line shell script to clipboard. Click **Paste & Run** button. | Modal preview dialog appears displaying the multiline snippet. Pressing **Cancel** aborts. Pressing **Run** executes safely. |
| **T17** | **Open in Konsole** | Click the **Open in Konsole** button in the header. | A standalone Konsole window opens detached in the active tab's current working directory. Repeating opens another independent window. |
| **T18** | **Terminal Tabs** | 1. Click **+** to add a new tab.<br>2. Switch between Tab 1 and Tab 2.<br>3. Close Tab 2. | New tab initializes with independent history and directory. Switching preserves buffer contents. Closing removes tab. |
| **T19** | **Background Tasks — Success** | Run a fast task in background. Expand **Tasks** collapsible. | Unit appears in Tasks list, state transitions from `running` to `done (0)`. Clicking **Logs** shows journalctl output. |
| **T20** | **Background Tasks — Failure** | Run `false` or `exit 1` in background. Expand **Tasks**. | Unit displays distinct red `failed (1)` badge. Clicking **Logs** shows failure trace. Clicking **Dismiss** clears the unit. |
| **T21** | **Background Tasks — Stop** | Run `sleep 60` in background. Expand **Tasks**. | Unit shows green `running` badge with **Stop** button. Clicking **Stop** halts unit immediately and removes it from running list. |

---

## 📝 Tester Results Template

Copy and fill this table for test reports:

| Feature | Steps | Expected | Result (Pass/Fail) | Notes |
| :--- | :--- | :--- | :--- | :--- |
| **T01: Global Shortcut** | Press `Meta+N` | Panel toggles | | |
| **T02: CLI Toggle** | Run `toggle-nevermore.sh` | Panel toggles | | |
| **T03: Tab Switching** | Click Widgets / Notifications / Run | Switched view | | |
| **T04: Calendar Grid** | Navigate months, click Today | Correct dates | | |
| **T05: Hardware Telemetry** | Check CPU, RAM, Disk, Net | Live gauges | | |
| **T06: Media Controls** | Play/pause external music | Controls work | | |
| **T07: Volume Sliders** | Drag master/mic sliders, mute | Audio adjusts | | |
| **T08: Notifications Feed**| Send notification, check tab | Card displayed | | |
| **T09: Notification Dismiss** | Dismiss single notification | Card removed | | |
| **T10: DND & Clear All** | Toggle DND, Clear All | Feed cleared | | |
| **T11: Command Execution** | Run `echo test` in Run tab | Output shown | | |
| **T12: Directory Tracking**| Run `cd /tmp && pwd` | CWD tracked | | |
| **T13: Exit Code Display**| Run `exit 42` | Red `[Exit 42]` | | |
| **T14: Process Group Stop**| Run `sleep 30`, click Stop | Terminated | | |
| **T15: Command Timeout** | Let command run > 30s | Exit 124 hint | | |
| **T16: Multiline Paste** | Paste multi-line script | Modal dialog | | |
| **T17: Open in Konsole** | Click Konsole button | Konsole opens | | |
| **T18: Terminal Tabs** | Add/switch/close tabs | Independent | | |
| **T19: Tasks (Success)** | Run `--bg` succeeding command | `done (0)` | | |
| **T20: Tasks (Failure)** | Run `--bg false` | `failed (1)` | | |
| **T21: Tasks (Stop)** | Run `--bg sleep 60`, click Stop | Unit stopped | | |
