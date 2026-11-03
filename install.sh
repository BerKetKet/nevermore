#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLASMOID_ID="io.github.berketket.nevermore"
PLASMOID_DIR="$HOME/.local/share/plasma/plasmoids/$PLASMOID_ID"
BIN_DIR="$HOME/.local/bin"
APP_DIR="$HOME/.local/share/applications"

MODE="install"
RESTART_SHELL=false

for arg in "$@"; do
    case "$arg" in
        --install|install)
            MODE="install"
            ;;
        --dev|dev)
            MODE="dev"
            ;;
        --uninstall|uninstall)
            MODE="uninstall"
            ;;
        --restart-shell)
            RESTART_SHELL=true
            ;;
        -h|--help)
            echo "Usage: $0 [--install | --dev | --uninstall] [--restart-shell]"
            exit 0
            ;;
        *)
            echo "Unknown option: $arg" >&2
            echo "Usage: $0 [--install | --dev | --uninstall] [--restart-shell]" >&2
            exit 1
            ;;
    esac
done

purge_legacy() {
    local legacy_raven_dir="$HOME/.local/share/plasma/plasmoids/org.kde.plasma.budgie.raven"
    local legacy_raven_bin="$BIN_DIR/toggle-raven.sh"
    local legacy_raven_desktop="$APP_DIR/toggle-raven.desktop"
    local deprecated_toggle_bin="$BIN_DIR/toggle-nevermore.sh"
    local deprecated_toggle_desktop="$APP_DIR/toggle-nevermore.desktop"

    # Clean up legacy Raven plasmoid files and backups
    rm -rf "$HOME/.local/share/plasma/plasmoids/org.kde.plasma.budgie.raven.bak"* 2>/dev/null || true
    if [ -L "$legacy_raven_dir" ] || [ -d "$legacy_raven_dir" ]; then
        rm -rf "$legacy_raven_dir"
        echo "✓ Removed legacy plasmoid directory: $legacy_raven_dir"
    fi
    if [ -f "$legacy_raven_bin" ] || [ -L "$legacy_raven_bin" ]; then
        rm -f "$legacy_raven_bin"
        echo "✓ Removed legacy toggle script: $legacy_raven_bin"
    fi
    if [ -f "$legacy_raven_desktop" ] || [ -L "$legacy_raven_desktop" ]; then
        rm -f "$legacy_raven_desktop"
        echo "✓ Removed legacy desktop entry: $legacy_raven_desktop"
    fi

    # Clean up deprecated Nevermore external toggle scripts
    if [ -f "$deprecated_toggle_bin" ] || [ -L "$deprecated_toggle_bin" ]; then
        rm -f "$deprecated_toggle_bin"
        echo "✓ Removed deprecated toggle script: $deprecated_toggle_bin"
    fi
    if [ -f "$deprecated_toggle_desktop" ] || [ -L "$deprecated_toggle_desktop" ]; then
        rm -f "$deprecated_toggle_desktop"
        echo "✓ Removed deprecated desktop entry: $deprecated_toggle_desktop"
    fi

    # Clean up kglobalaccel registrations for deprecated external toggle actions
    if command -v python3 >/dev/null 2>&1; then
        python3 -c '
try:
    import gi
    from gi.repository import Gio, GLib
    bus = Gio.bus_get_sync(Gio.BusType.SESSION, None)
    for act in ["toggle-nevermore.desktop", "toggle-raven.desktop"]:
        try:
            bus.call_sync("org.kde.kglobalaccel", "/kglobalaccel", "org.kde.KGlobalAccel", "unregister", GLib.Variant("(ss)", (act, "_launch")), None, Gio.DBusCallFlags.NONE, 1000, None)
        except Exception:
            pass
except Exception:
    pass
' 2>/dev/null || true
    fi
}

install_runner() {
    mkdir -p "$BIN_DIR"
    cp "$REPO_DIR/scripts/nevermore-run" "$BIN_DIR/nevermore-run"
    chmod +x "$BIN_DIR/nevermore-run"
    echo "✓ Installed runner helper to $BIN_DIR/nevermore-run"

    cp "$REPO_DIR/scripts/nevermore-raise" "$BIN_DIR/nevermore-raise"
    chmod +x "$BIN_DIR/nevermore-raise"
    echo "✓ Installed window raise helper to $BIN_DIR/nevermore-raise"
}

restart_plasmashell() {
    echo "Restarting plasma-plasmashell.service..."
    rm -rf "$HOME/.cache/plasmashell/qmlcache"/* 2>/dev/null || true
    if command -v systemctl >/dev/null 2>&1; then
        systemctl --user stop "app-plasmashell@*.service" 2>/dev/null || true
        systemctl --user restart plasma-plasmashell.service 2>/dev/null || true
        sleep 2
        echo "✓ Restarted plasma-plasmashell.service"
    fi
}

case "$MODE" in
    uninstall)
        echo "=== Uninstalling Nevermore Control Center ==="
        purge_legacy

        if [ -f "$BIN_DIR/nevermore-run" ] || [ -L "$BIN_DIR/nevermore-run" ]; then
            rm -f "$BIN_DIR/nevermore-run"
            echo "✓ Removed $BIN_DIR/nevermore-run"
        fi

        if [ -f "$BIN_DIR/nevermore-raise" ] || [ -L "$BIN_DIR/nevermore-raise" ]; then
            rm -f "$BIN_DIR/nevermore-raise"
            echo "✓ Removed $BIN_DIR/nevermore-raise"
        fi

        # Safely remove plasmoid without following symlinks into source repo
        if [ -L "$PLASMOID_DIR" ]; then
            rm -f "$PLASMOID_DIR"
            echo "✓ Removed developer symlink: $PLASMOID_DIR"
        elif [ -d "$PLASMOID_DIR" ]; then
            if command -v kpackagetool6 >/dev/null 2>&1; then
                if kpackagetool6 -t Plasma/Applet --show "$PLASMOID_ID" >/dev/null 2>&1; then
                    kpackagetool6 -t Plasma/Applet -r "$PLASMOID_ID" >/dev/null 2>&1 || true
                fi
            fi
            rm -rf "$PLASMOID_DIR"
            echo "✓ Removed plasmoid directory: $PLASMOID_DIR"
        fi

        if command -v kbuildsycoca6 >/dev/null 2>&1; then
            kbuildsycoca6 >/dev/null 2>&1 || true
        fi

        if [ "$RESTART_SHELL" = true ]; then
            restart_plasmashell
        fi

        echo "=== Nevermore uninstalled successfully ==="
        ;;

    dev)
        echo "=== Setting Up Nevermore in Developer (Symlink) Mode ==="
        purge_legacy
        install_runner

        mkdir -p "$(dirname "$PLASMOID_DIR")"

        # If an installed copy exists (real directory), remove it first
        if [ -d "$PLASMOID_DIR" ] && [ ! -L "$PLASMOID_DIR" ]; then
            if command -v kpackagetool6 >/dev/null 2>&1; then
                kpackagetool6 -t Plasma/Applet -r "$PLASMOID_ID" >/dev/null 2>&1 || true
            fi
            rm -rf "$PLASMOID_DIR"
        fi

        ln -sfn "$REPO_DIR" "$PLASMOID_DIR"
        echo "✓ Symlinked repository to $PLASMOID_DIR"

        if command -v kbuildsycoca6 >/dev/null 2>&1; then
            kbuildsycoca6 >/dev/null 2>&1 || true
        fi

        if [ "$RESTART_SHELL" = true ]; then
            restart_plasmashell
        fi

        echo "=== Developer setup complete ==="
        echo "Next steps:"
        echo "1. Add Nevermore to your right-edge panel: Right-click panel -> Add Widgets... -> drag Nevermore onto the panel."
        echo "2. Configure shortcut: Right-click Nevermore -> Configure Nevermore... -> Keyboard Shortcuts -> set Meta+N."
        echo "3. To reload changes after editing QML: ./install.sh --dev --restart-shell"
        ;;

    install)
        echo "=== Installing Nevermore Control Center ==="
        purge_legacy
        install_runner

        # If a symlink exists from dev mode, clear it safely
        if [ -L "$PLASMOID_DIR" ]; then
            rm -f "$PLASMOID_DIR"
            echo "✓ Cleared previous developer symlink at $PLASMOID_DIR"
        fi

        if ! command -v kpackagetool6 >/dev/null 2>&1; then
            echo "Error: kpackagetool6 is not found in PATH." >&2
            exit 1
        fi

        if kpackagetool6 -t Plasma/Applet --show "$PLASMOID_ID" >/dev/null 2>&1; then
            echo "Upgrading existing package..."
            kpackagetool6 -t Plasma/Applet -u "$REPO_DIR"
        else
            echo "Installing package..."
            kpackagetool6 -t Plasma/Applet -i "$REPO_DIR"
        fi
        echo "✓ Installed plasmoid package via kpackagetool6"

        if command -v kbuildsycoca6 >/dev/null 2>&1; then
            kbuildsycoca6 >/dev/null 2>&1 || true
        fi

        if [ "$RESTART_SHELL" = true ]; then
            restart_plasmashell
        fi

        echo "=== Nevermore installed successfully ==="
        echo "Next steps:"
        echo "1. Add Nevermore to your right-edge panel: Right-click panel -> Add Widgets... -> drag Nevermore onto the panel."
        echo "2. Configure shortcut: Right-click Nevermore -> Configure Nevermore... -> Keyboard Shortcuts -> set Meta+N."
        echo "3. To reload changes after updates: ./install.sh --restart-shell"
        ;;
esac
