# 🗺️ Nevermore Development Roadmap

This document outlines the structured development phases and architectural roadmap for the Nevermore Control Center plasmoid.

---

## Phases

### Phase 0: Identity and Hygiene
- Establish canonical identity: `io.github.berketket.nevermore` (Version 0.1.0, GPL-3.0-or-later).
- Align minimum Plasma version (Plasma 6.0) and clean up obsolete Plasma 5 metadata keys.
- Overhaul `install.sh` supporting package installation (`kpackagetool6`), developer symlinking (`--dev`), and uninstallation (`--uninstall`).
- Continuous Integration via GitHub Actions running `shellcheck` and `qmllint`.

### Phase 1: Correctness Fixes
- Correct `Qt.rgba` channel scaling to `[0.0, 1.0]`.
- Audio volume widget cleanup: remove artificial fallbacks and handle device absence gracefully.
- Hardware telemetry optimization: pause telemetry updates when tab/plasmoid is hidden.
- Notification model unification: deduplicate `NM.Notifications` to single shared instance.
- Media controls cleanup: direct ID references replacing child indexing.

### Phase 2: Command Runner & Notifications Hardening
- Implement transient systemd background task launcher (`systemd-run --user`).
- Tasks inspection with JSON listing and journalctl log retrieval.
- Notification click-through handling with default action execution.
- Window raising fallback via `nevermore-raise` for notifications without actions.

### Phase 2e: Single Instance, Single Surface Architecture
- Eliminate dual-instance split: exactly one plasmoid instance resides in the right autohide panel.
- Pure popup architecture: `preferredRepresentation: compactRepresentation`, forcing the entire control center to render exclusively within Plasma's native floating dialog (`PlasmaQuick::Dialog`).
- Native shortcut toggle: `activationTogglesExpanded: true` natively toggles `root.expanded` on `Meta+N`.
- Zero desktop window shift across shortcut and edge hover activations.

### Phase 3b: Managed Terminal Window, Panel Fix, Consolidation
- Panel thickness optimization: set right-edge autohide panel to 24 px (Plasma 6 minimum), reducing popup gap to 24 px.
- Decision record (`docs/spikes/terminal.md`): document rejection of embedded QML terminal and shift to managed external terminal window.
- Managed external terminal (`scripts/nevermore-term`): launch and control dedicated Konsole window docked to right screen edge (`397 px` width, full available height).
- Tiling isolation: enforce KWin window rule (Utility type 16) and Krohnkite ignore configuration ensuring 0 px window shift/resize of open applications.
- Global shortcut: `Meta+Shift+N` (and `nevermore-term toggle`) to slide terminal in and out.
- Tab rework: replace Run tab with Terminal tab, providing prominent Show/Hide toggle, live status, and background tasks management.
- Helper streamlining: simplify `nevermore-run` strictly to transient background task submission; eliminate obsolete one-shot runner, base64 args, stop-markers, and PID files.

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

- **Embedded QML Terminal (QMLTermWidget / tmux / xterm.js):** Evaluated and rejected. Embedded QML terminal widgets suffer from Wayland focus routing failures, missing shell capabilities, and cannot host Konsole's QWidget KPart. Managed external window architecture provides 100% native terminal fidelity.
- **Calendar Reminders & Tasks (Google Calendar Sync):** Deferred pending future Google Calendar synchronization integration; interactive month grid remains purely local.
- **Weather & Forecast Card:** Deferred pending evaluation of lightweight, zero-key public weather APIs.
