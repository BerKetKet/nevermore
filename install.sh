#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLASMOID_ID="io.github.berketket.nevermore"
PLASMOID_DIR="$HOME/.local/share/plasma/plasmoids/$PLASMOID_ID"
BIN_DIR="$HOME/.local/bin"
APP_DIR="$HOME/.local/share/applications"

purge_legacy() {
    local legacy_dir="$HOME/.local/share/plasma/plasmoids/org.kde.plasma.budgie.raven"
    local legacy_bin="$BIN_DIR/toggle-raven.sh"
    local legacy_desktop="$APP_DIR/toggle-raven.desktop"

    if [ -L "$legacy_dir" ] || [ -d "$legacy_dir" ]; then
        rm -rf "$legacy_dir"
        echo "✓ Removed legacy plasmoid directory: $legacy_dir"
    fi
    if [ -f "$legacy_bin" ] || [ -L "$legacy_bin" ]; then
        rm -f "$legacy_bin"
        echo "✓ Removed legacy toggle script: $legacy_bin"
    fi
    if [ -f "$legacy_desktop" ] || [ -L "$legacy_desktop" ]; then
        rm -f "$legacy_desktop"
        echo "✓ Removed legacy desktop entry: $legacy_desktop"
    fi
}

install_helper_files() {
    mkdir -p "$BIN_DIR" "$APP_DIR"

    # Install toggle script
    cp "$REPO_DIR/scripts/toggle-nevermore.sh" "$BIN_DIR/toggle-nevermore.sh"
    chmod +x "$BIN_DIR/toggle-nevermore.sh"
    echo "✓ Installed toggle script to $BIN_DIR/toggle-nevermore.sh"

    # Install runner script
    cp "$REPO_DIR/scripts/nevermore-run" "$BIN_DIR/nevermore-run"
    chmod +x "$BIN_DIR/nevermore-run"
    echo "✓ Installed runner script to $BIN_DIR/nevermore-run"

    # Generate desktop entry with real runtime paths
    cat > "$APP_DIR/toggle-nevermore.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Toggle Nevermore Control Center
Comment=Toggle Nevermore sidebar panel visibility
Exec=$BIN_DIR/toggle-nevermore.sh
Icon=sidebar-expand-right
NoDisplay=true
X-KDE-GlobalAccel-CommandShortcut=true
Categories=Utility;
EOF
    chmod +x "$APP_DIR/toggle-nevermore.desktop"
    echo "✓ Generated desktop entry at $APP_DIR/toggle-nevermore.desktop"

    if command -v kbuildsycoca6 >/dev/null 2>&1; then
        kbuildsycoca6 >/dev/null 2>&1 || true
    fi
}

MODE="${1:---install}"

case "$MODE" in
    --uninstall)
        echo "=== Uninstalling Nevermore Control Center ==="
        purge_legacy

        if command -v kpackagetool6 >/dev/null 2>&1; then
            if kpackagetool6 -t Plasma/Applet --show "$PLASMOID_ID" >/dev/null 2>&1; then
                kpackagetool6 -t Plasma/Applet -r "$PLASMOID_ID" >/dev/null 2>&1 || true
            fi
        fi

        if [ -L "$PLASMOID_DIR" ] || [ -d "$PLASMOID_DIR" ]; then
            rm -rf "$PLASMOID_DIR"
            echo "✓ Removed plasmoid directory: $PLASMOID_DIR"
        fi

        if [ -f "$BIN_DIR/toggle-nevermore.sh" ] || [ -L "$BIN_DIR/toggle-nevermore.sh" ]; then
            rm -f "$BIN_DIR/toggle-nevermore.sh"
            echo "✓ Removed $BIN_DIR/toggle-nevermore.sh"
        fi

        if [ -f "$BIN_DIR/nevermore-run" ] || [ -L "$BIN_DIR/nevermore-run" ]; then
            rm -f "$BIN_DIR/nevermore-run"
            echo "✓ Removed $BIN_DIR/nevermore-run"
        fi

        if [ -f "$APP_DIR/toggle-nevermore.desktop" ] || [ -L "$APP_DIR/toggle-nevermore.desktop" ]; then
            rm -f "$APP_DIR/toggle-nevermore.desktop"
            echo "✓ Removed $APP_DIR/toggle-nevermore.desktop"
        fi

        if command -v kbuildsycoca6 >/dev/null 2>&1; then
            kbuildsycoca6 >/dev/null 2>&1 || true
        fi

        echo "=== Nevermore uninstalled successfully ==="
        ;;

    --dev)
        echo "=== Installing Nevermore in Developer (Symlink) Mode ==="
        purge_legacy
        mkdir -p "$(dirname "$PLASMOID_DIR")"

        if [ -d "$PLASMOID_DIR" ] && [ ! -L "$PLASMOID_DIR" ]; then
            if command -v kpackagetool6 >/dev/null 2>&1; then
                kpackagetool6 -t Plasma/Applet -r "$PLASMOID_ID" >/dev/null 2>&1 || true
            fi
            rm -rf "$PLASMOID_DIR"
        fi

        ln -sfn "$REPO_DIR" "$PLASMOID_DIR"
        echo "✓ Symlinked repository to $PLASMOID_DIR"

        install_helper_files
        echo "=== Nevermore developer symlink setup complete ==="
        ;;

    --install|install|"")
        echo "=== Installing Nevermore Control Center ==="
        purge_legacy

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

        install_helper_files
        echo "=== Nevermore installed successfully ==="
        ;;

    *)
        echo "Usage: $0 [--install | --dev | --uninstall]" >&2
        exit 1
        ;;
esac
