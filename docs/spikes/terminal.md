# Decision Record: Embedded vs Managed Terminal Window Architecture

**Date:** 2026-11-03  
**Status:** Decided  
**Target:** KDE Plasma 6 (Wayland)  

---

## 1. Goal
Provide an interactive terminal integrated with Nevermore that supports the user's authentic shell environment (`/bin/zsh`, custom `.zshrc`, prompt themes, history), full-screen TUI applications (`htop`, `vim`, `nano`, `less`), hidden-echo password prompts (`sudo -v`), tab-completion grids, and seamless workflow continuity without compromising stability or input latency.

---

## 2. Options Considered

1. **Option 1: Embedded `QMLTermWidget` over dedicated headless `tmux`**
   - Attempted embedding `QMLTermWidget` (Konsole's terminal core packaged as a Qt 6 Quick Item) attached via PTY to a dedicated headless tmux server on an isolated domain socket (`tmux -L nevermore`).
2. **Option 2: Pure QML Terminal via `tmux capture-pane` Polling**
   - Rejected without building: Periodic polling produces 5–15% CPU load, sub-process spawning lag, and lacks a bidirectional ANSI/VT100 escape sequence interpreter in pure QML.
3. **Option 3: Embedded `xterm.js` via `QtWebEngine`**
   - Rejected without building: Adds a ~150–250 MB Chromium runtime overhead, multi-second cold startup times, and complex WebSocket/PTY bridging.
4. **Option 4: Embedded Konsole KPart**
   - Evaluated and rejected as technically impossible: Konsole's official embeddable component is a QWidget-based `KPart` (`Konsole::Part`). A KDE Plasma 6 plasmoid is written in pure Qt Quick / QML rendered via the Plasma scene graph and cannot host legacy QWidget KParts.
5. **Option 5: Managed Dedicated External Terminal Emulator Window**
   - Run a dedicated instance of a real terminal emulator (`konsole --separate` by default, configurable via `~/.config/nevermore/terminal.conf`), positioned and styled dynamically on the right screen edge via KWin scripting and window rules.

---

## 3. Human Test Outcome of the Embedded Spike (Option 1)

The Phase 3a `QMLTermWidget` + `tmux` spike was tested on live hardware:
- **Result:** **REJECTED**.
- **Outcome Details:** Only click-to-focus functioned satisfactorily; the rest of the interactive experience (keyboard routing, shell fidelity, rendering behavior) was unsatisfactory (per-item breakdown details were not recorded).
- **Conclusion:** Embedding experimental QML terminal widgets inside a slide-out Plasma control center causes severe input handling and compositor routing friction on Wayland.

---

## 4. Evaluation of Yakuake for Right-Edge Docking

**Question:** Could Yakuake be used to dock a slide-out window to the right edge on Wayland?  
**Result:** **NO**.  
**Evidence:**
- Yakuake (tested version: `26.08.2-1.1`, installed at `/usr/bin/yakuake`) is architecturally hardcoded as a top drop-down terminal modeled on the Quake console.
- Inspection of Yakuake configuration options (`kcfg_Position`) and upstream KDE documentation confirms that `Position` only adjusts horizontal offset along the top edge (0=left, 50=center, 100=right). It provides no capability to dock or slide out vertically from the left, bottom, or right screen edges.

---

## 5. Architectural Decision

**Decision:** Adopt **Option 5: Managed Dedicated External Terminal Window**.

### Architectural Blueprint:
1. **Nevermore Terminal Controller (`scripts/nevermore-term`)**:
   - Manages a standalone terminal process (`konsole --separate` with a dedicated profile by default, or user-defined emulator via `~/.config/nevermore/terminal.conf`).
   - Identifies the window strictly by its spawned Process ID (PID), rather than fragile window class matching.
   - Provides subcommands: `toggle`, `show`, `hide`, and `status`.
2. **KWin Script Placement & Window Rules**:
   - Positions the terminal window at the right screen edge (397 px width, full available screen height).
   - Sets attributes: `keepAbove = true`, `skipTaskbar = true`, `skipPager = true`, `skipSwitcher = true`, `noBorder = true`.
   - Manages toggle state: minimizes when currently active; restores, repositions, and activates when hidden or inactive.
3. **Tiling Window Manager (Krohnkite) Isolation**:
   - Enforces a dedicated KWin window rule or floating type so that Krohnkite does not tile the terminal window and does not shift or resize any other tiled window (e.g. Google Chrome).
4. **Nevermore Applet Integration**:
   - The **Run** tab is rebranded to **Terminal**, featuring a prominent **Show/Hide Terminal** button and status indicator alongside the background Tasks manager.
