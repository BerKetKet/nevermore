#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLASMOID_ID="io.github.berketket.nevermore"
PLASMOID_DIR="$HOME/.local/share/plasma/plasmoids/$PLASMOID_ID"
BIN_DIR="$HOME/.local/bin"
APP_DIR="$HOME/.local/share/applications"

MODE="install"
RESTART_SHELL=false
AUTOSTART_TERMINAL=false
KROHNKITE_RULE=false

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
        --autostart-terminal)
            AUTOSTART_TERMINAL=true
            ;;
        --krohnkite-rule)
            KROHNKITE_RULE=true
            ;;
        -h|--help)
            echo "Usage: $0 [--install | --dev | --uninstall] [--restart-shell] [--autostart-terminal] [--krohnkite-rule]"
            exit 0
            ;;
        *)
            echo "Unknown option: $arg" >&2
            echo "Usage: $0 [--install | --dev | --uninstall] [--restart-shell] [--autostart-terminal] [--krohnkite-rule]" >&2
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

apply_kwin_window_rules() {
    local rules_file="$HOME/.config/kwinrulesrc"
    if [ -f "$rules_file" ]; then
        if ! grep -q "nevermore-terminal-rule" "$rules_file"; then
            cat >> "$rules_file" <<'EOF'

[nevermore-terminal-rule]
Description=Nevermore Managed Terminal
above=true
aboverule=3
noborder=true
noborderrule=3
skippager=true
skippagerrule=3
skipswitcher=true
skipswitcherrule=3
skiptaskbar=true
skiptaskbarrule=3
types=16
typesrule=3
wmclass=io.github.berketket.nevermore.terminal
wmclasscomplete=true
wmclassmatch=1
EOF
            sed -i '/^Order=/ s/$/,nevermore-terminal-rule/' "$rules_file"
            echo "✓ Added KWin window rule for Nevermore terminal"
        fi
    fi

    local kwinrc="$HOME/.config/kwinrc"
    if [ -f "$kwinrc" ]; then
        if grep -q "\[Script-krohnkite\]" "$kwinrc"; then
            if ! grep -q "io.github.berketket.nevermore.terminal" "$kwinrc"; then
                sed -i '/^\[Script-krohnkite\]/a ignoreClass=io.github.berketket.nevermore.terminal' "$kwinrc"
                echo "✓ Added ignoreClass to Krohnkite configuration"
            fi
        fi
    fi

    if command -v qdbus6 >/dev/null 2>&1; then
        qdbus6 org.kde.KWin /KWin org.kde.KWin.reconfigure >/dev/null 2>&1 || true
    fi
}

remove_kwin_window_rules() {
    local rules_file="$HOME/.config/kwinrulesrc"
    if [ -f "$rules_file" ]; then
        sed -i 's/,nevermore-terminal-rule//g' "$rules_file"
        sed -i 's/nevermore-terminal-rule,//g' "$rules_file"
        python3 -c '
import configparser
path = "'"$rules_file"'"
cp = configparser.ConfigParser()
cp.read(path)
if cp.has_section("nevermore-terminal-rule"):
    cp.remove_section("nevermore-terminal-rule")
    with open(path, "w") as f:
        cp.write(f, space_around_delimiters=False)
' 2>/dev/null || true
    fi

    local kwinrc="$HOME/.config/kwinrc"
    if [ -f "$kwinrc" ]; then
        sed -i '/ignoreClass=io\.github\.berketket\.nevermore\.terminal/d' "$kwinrc"
    fi

    if command -v qdbus6 >/dev/null 2>&1; then
        qdbus6 org.kde.KWin /KWin org.kde.KWin.reconfigure >/dev/null 2>&1 || true
    fi
}

install_helpers() {
    mkdir -p "$BIN_DIR"
    cp "$REPO_DIR/scripts/nevermore-run" "$BIN_DIR/nevermore-run"
    chmod +x "$BIN_DIR/nevermore-run"
    echo "✓ Installed runner helper to $BIN_DIR/nevermore-run"

    cp "$REPO_DIR/scripts/nevermore-raise" "$BIN_DIR/nevermore-raise"
    chmod +x "$BIN_DIR/nevermore-raise"
    echo "✓ Installed window raise helper to $BIN_DIR/nevermore-raise"

    cp "$REPO_DIR/scripts/nevermore-term" "$BIN_DIR/nevermore-term"
    chmod +x "$BIN_DIR/nevermore-term"
    echo "✓ Installed terminal helper to $BIN_DIR/nevermore-term"

    local prof_dir="$HOME/.local/share/konsole"
    mkdir -p "$prof_dir"
    cp "$REPO_DIR/profiles/Nevermore.profile" "$prof_dir/Nevermore.profile"
    echo "✓ Installed Konsole profile to $prof_dir/Nevermore.profile"

    mkdir -p "$APP_DIR"
    cp "$REPO_DIR/contents/desktop/io.github.berketket.nevermore.terminal.desktop" "$APP_DIR/io.github.berketket.nevermore.terminal.desktop"
    echo "✓ Installed desktop entry to $APP_DIR/io.github.berketket.nevermore.terminal.desktop"

    if [ "$AUTOSTART_TERMINAL" = true ]; then
        local autostart_dir="$HOME/.config/autostart"
        mkdir -p "$autostart_dir"
        cat > "$autostart_dir/nevermore-terminal.desktop" <<'EOF'
[Desktop Entry]
Name=Nevermore Terminal (Autostart)
Comment=Autostart Nevermore managed terminal minimized
Exec=nevermore-term start-minimized
Icon=utilities-terminal
Type=Application
Terminal=false
Categories=System;TerminalEmulator;
X-GNOME-Autostart-enabled=true
EOF
        echo "✓ Configured autostart entry: $autostart_dir/nevermore-terminal.desktop"
    fi

    if [ "$KROHNKITE_RULE" = true ]; then
        apply_kwin_window_rules
    fi
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
        remove_kwin_window_rules

        if [ -f "$BIN_DIR/nevermore-run" ] || [ -L "$BIN_DIR/nevermore-run" ]; then
            rm -f "$BIN_DIR/nevermore-run"
            echo "✓ Removed $BIN_DIR/nevermore-run"
        fi

        if [ -f "$BIN_DIR/nevermore-raise" ] || [ -L "$BIN_DIR/nevermore-raise" ]; then
            rm -f "$BIN_DIR/nevermore-raise"
            echo "✓ Removed $BIN_DIR/nevermore-raise"
        fi

        if [ -f "$BIN_DIR/nevermore-term" ] || [ -L "$BIN_DIR/nevermore-term" ]; then
            rm -f "$BIN_DIR/nevermore-term"
            echo "✓ Removed $BIN_DIR/nevermore-term"
        fi

        if [ -f "$APP_DIR/io.github.berketket.nevermore.terminal.desktop" ] || [ -L "$APP_DIR/io.github.berketket.nevermore.terminal.desktop" ]; then
            rm -f "$APP_DIR/io.github.berketket.nevermore.terminal.desktop"
            echo "✓ Removed $APP_DIR/io.github.berketket.nevermore.terminal.desktop"
        fi

        if [ -f "$HOME/.config/autostart/nevermore-terminal.desktop" ] || [ -L "$HOME/.config/autostart/nevermore-terminal.desktop" ]; then
            rm -f "$HOME/.config/autostart/nevermore-terminal.desktop"
            echo "✓ Removed $HOME/.config/autostart/nevermore-terminal.desktop"
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
        install_helpers

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
        install_helpers

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
