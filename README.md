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
| **Command Execution Tab** | **Implemented** | One-shot command runner with exit code detection and output log. |
| **Command History** | *Partial* | In-memory session history (cleared on plasmoid restart). |
| **Wayland Clipboard Paste**| **Implemented** | Paste commands from Wayland clipboard (`wl-paste`) with multiline safety check. |
| **Global Shortcut** | *Manual* | Configured manually via KDE System Settings (`Meta+N`). |

---

## 💻 Requirements

* **KDE Plasma:** Version 6.0 or higher (tested on Plasma 6.8.2 on Wayland).
* **Qt / Frameworks:** Qt 6.x, Kirigami 3 / KF6.
* **Wayland Clipboard Utility:** `wl-clipboard` (provides `wl-paste` for clipboard actions).
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

To bind the **`Meta + N`** shortcut to toggle Nevermore:

1. Open **System Settings** -> **Keyboard** -> **Shortcuts**.
2. Click **Add New** -> **Command or Script** (or find **Toggle Nevermore Control Center** under Applications).
3. Set the command to:
   ```bash
   ~/.local/bin/toggle-nevermore.sh
   ```
4. Click the shortcut button, press **`Meta + N`**, and click **Apply**.

---

## ⚠️ Known Issues & Technical Notes

* **Disk Utilization Sensor:** Nevermore currently tracks aggregate filesystem utilization across all mounts via the sensor `disk/all/usedPercent` rather than partition-specific UUIDs, ensuring compatibility across differing partition setups.
* **Global Shortcut Registration:** Plasma 6 Wayland requires explicit user authorization in System Settings for custom command shortcuts; automated registration via background scripts is not durable across sessions.
* **Command Persistence:** Command runner history is currently maintained in memory during the active session. If plasmashell restarts, command runner tabs and history reset to the default workspace.

---

## 🗺️ Roadmap

See [docs/ROADMAP.md](docs/ROADMAP.md) for detailed phase breakdowns and upcoming milestones.

---

## 📜 License

Licensed under the **GNU General Public License v3.0 or later** ([GPL-3.0-or-later](LICENSE)).
