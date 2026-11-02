# 🦅 Nevermore

> *"Quoth the Raven, 'Nevermore.'"* — Edgar Allan Poe

**Nevermore** is an advanced, modular, and aesthetic slide-out **Control Center** for **KDE Plasma 6 (Wayland)**. Built to transcend the limitations of sparse desktop applets, Nevermore delivers a unified, high-density dashboard inspired by Budgie's *Raven* and macOS's *Notification Center*—engineered to be **the control center to end all control centers**.

---

## ✨ Features at a Glance

### 1. 🗂️ Segmented Multi-Tab Flyout
A clean, frosted-acrylic right-hand flyout with dedicated, instant-access tabs:
* **`[ Widgets ]`**: Hardware telemetry, calendar, media, and sound.
* **`[ Notifications ]`**: Actionable alert history, Do Not Disturb, and bulk clearing.
* **`[ Terminal ]`**: Multi-session quick scratchpad & execution terminal.

---

### 2. 📊 Widgets & System Telemetry (Inline, Zero Hovering)
Unlike traditional panels that force applets into collapsed icon popups, Nevermore exposes high-contrast, real-time gauges inline:
* **Interactive Month Calendar:** Complete 7x6 month grid (42 days) with previous/next month navigation, "Today" quick-jump, and vibrant current-day highlighting.
* **CPU Load Gauge:** Live CPU utilization meter with core statistics and color-coded stress levels.
* **RAM Telemetry:** Real-time RAM utilization bar with formatted `Used GB / Total GB` and percentages.
* **Storage Space:** Real-time root disk capacity monitor showing free space and utilization percentages.
* **Network Throughput:** Instant upload and download speed meters.
* **MPRIS Media Player:** Automatically detects active media streams (YouTube, Spotify, VLC) displaying album art, song title, artist/channel, and playback controls (Prev / Play-Pause / Next).
* **Audio Sliders:** Granular output and microphone volume controls with single-click mute switches.

---

### 3. 🔔 Notifications Feed
* **Full History:** Freedesktop notification aggregator with application icons, timestamps, and expandable content.
* **Interactive Actions:** Per-alert dismissal and global **Clear All**.
* **Do Not Disturb (DND):** Toggle DND mode directly from the header to silence incoming desktop interruptions.
* **Unread Counter:** Real-time badge counter on the tab header.

---

### 4. 💻 Multi-Tab Quick Terminal
* **Multi-Session Management:** Open concurrent terminal tabs (`Tab 1`, `Tab 2`, `+`) with individual working directories and command logs.
* **`[ 📋 Paste & Run ]`:** Instant Wayland clipboard extraction (`wl-paste`) to paste and execute terminal commands in one click.
* **Persistent History:** Retains session logs until explicitly cleared with the `Clear` button.
* **Working Directory Tracking:** Tracks `cd` commands across runs so subsequent executions remain in the target directory.

---

### 5. 🚀 Wayland-Native Activation & Shortcuts
* **Right Edge Slide:** Configured with Plasma's native auto-hide; hovering the right screen edge slides the panel into view.
* **Global Shortcut:** Press **`Super + N`** (`Meta + N`, Budgie's signature shortcut) to toggle the sidebar pinned open or dismissed back to autohide.

---

## 🛠️ Architecture & Tech Stack

* **Platform:** KDE Plasma 6.8+ on Wayland
* **Frontend:** QtQuick 6, Kirigami 2/6, Plasma Quick components
* **Backend Interfaces:**
  * System telemetry via `org.kde.ksysguard.sensors` & `ksystemstats`
  * Media controls via DBus MPRIS (`org.kde.plasma.private.mpris`)
  * Sound via PulseAudio / PipeWire (`org.kde.plasma.private.volume`)
  * Notifications via `org.kde.notificationmanager`
  * Execution engine via `Plasma5Support.DataSource` and native bash

---

## 📦 Installation & Development

```bash
# Clone the repository
git clone https://github.com/BerKetKet/nevermore.git ~/projects/nevermore
cd ~/projects/nevermore

# Run installer (symlinks plasmoid, installs scripts and shortcuts)
./install.sh
```

---

## 🗺️ Roadmap & Upcoming Refinements

* [ ] **Terminal Architecture Redesign:** Dedicated process manager for long-running / daemon tasks (keeping background processes active and monitored out-of-the-way).
* [ ] **Embedded PTY Terminal:** Inline interactive terminal with a live blinking cursor, raw input capture, and full shell emulation.
* [ ] **Customizable Widget Grid:** Drag-and-drop reordering of widgets and user-toggleable cards.
* [ ] **Quick Toggles Matrix:** Wi-Fi, Bluetooth, VPN, Night Light, and performance power profiles.
* [ ] **Weather & Forecast Card:** Detailed hourly weather radar and temperature widget.

---

## 📜 License
GPLv3 License. Inspired by the Buddies of Budgie Raven sidebar and macOS design principles.
