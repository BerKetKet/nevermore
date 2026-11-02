# 🗺️ Nevermore Development Roadmap

This document outlines the structured development phases and architectural roadmap for the Nevermore Control Center plasmoid.

---

## Phases

### Phase 0: Identity and Hygiene (Current)
- Establish canonical identity: `io.github.berketket.nevermore` (Version 0.1.0, GPL-3.0-or-later).
- Align minimum Plasma version (Plasma 6.0) and clean up obsolete Plasma 5 metadata keys (`ServiceTypes`, `X-Plasma-NotificationArea`, `X-Plasma-Provides`).
- Refactor helper scripts (`toggle-nevermore.sh`) with robust `qdbus6`/`qdbus` detection.
- Overhaul `install.sh` supporting package installation (`kpackagetool6`), developer symlinking (`--dev`), and uninstallation (`--uninstall`).
- Honest README audit and documentation of manual shortcut registration.
- Continuous Integration via GitHub Actions running `shellcheck` and `qmllint` (syntax, scoping, and structural verification without module type resolution).

### Phase 1: Correctness Fixes
- Correct `Qt.rgba` calls to ensure channel values remain strictly within the standard `[0.0, 1.0]` range.
- Audio volume widget cleanup: remove artificial fallback values (60, 80, 50) and gracefully disable controls when no sink/source device is present.
- Hardware telemetry optimization: eliminate redundant polling timers, pause telemetry updates when the tab/plasmoid is hidden, and honestly label aggregate disk metrics.
- Notification model unification: deduplicate `NM.Notifications` to a single shared instance, enforce explicit `textFormat` (StyledText for body, PlainText for summary), and use documented API flags instead of magic numbers.
- Media controls cleanup: replace fragile child indexing (`parent.children[0].status`) with direct ID references.
- Internationalization compliance: replace string concatenation in `i18n()` with parameterized placeholders (`%1`).
- Audit `CalendarWidget.qml` and `WidgetsTab.qml` for data hygiene and styling consistency.

### Phase 2: Quick Run Tab
- Transition from simulated terminal to an honest, robust one-shot command runner (Quick Run).
- Create `scripts/nevermore-run` helper with base64-encoded parameter passing, sentinel output tokens, and process isolation.
- Capture real process exit codes with color-coded success/failure indicators.
- Reliable process termination using process group killing (`setsid` and `kill -- -PID`).
- Timeout handling with visual warning and shortcut to launch command in detached Konsole.
- Detached terminal launch button (`Open in Konsole`).
- Clipboard paste helper (`wl-paste`) with multiline safety confirmation before execution.
- Runtime working directory resolution and monotonic tab identification.
- Long-running background task launcher (`systemd-run --user`).

### Phase 3: Theme Tokens and Reusable Components
- Centralized `Theme.qml` singleton defining system palette tokens, spacing, radiuses, and transition timings.
- Component library: `Card.qml`, `Gauge.qml`, `IconButton.qml`, and `SectionHeader.qml`.
- Typography standardization: replace hardcoded font families (`SF Hello`, `SF Mono`) with platform system font fallbacks (`Kirigami.Theme.defaultFont`, monospace font fallback).

### Phase 4: Quick Toggles
- High-density toggle matrix in the control center header:
  - Wi-Fi network switch and status.
  - Bluetooth power toggle and paired devices.
  - VPN tunnel connection toggle.
  - Night Light (blue light filter) quick toggle.
  - Power profiles (Performance, Balanced, Power-saver).

### Phase 5: Notification Actions and Timestamps
- Relative timestamp rendering (e.g. "Just now", "5m ago", "Yesterday").
- Interactive notification action buttons (reply, open, dismiss).
- Expandable notification body view for multi-line and rich formatted alerts.

---

## Deferred / Dropped Features

- **Real qmllint with KDE Module Stubs:** In CI runners without KDE Plasma/KF6 packages installed, `qmllint` must run with `--unresolved-type disable --missing-property disable`. Providing offline mock type stubs or dummy `qmldir` modules for `org.kde.*` in CI to enable full semantic verification is slated for a future tooling update.
- **Embedded PTY Terminal:** Dropped in favor of the lightweight Quick Run runner and external Konsole integration. Full PTY emulation within QML introduces unnecessary complexity, security hazards, and rendering inefficiencies.
- **Weather & Forecast Card:** Deferred pending evaluation of lightweight, zero-key public weather APIs.
