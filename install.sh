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

    # Remove stale backup directories and QML bytecode cache
    rm -rf "$HOME/.local/share/plasma/plasmoids/org.kde.plasma.budgie.raven.bak"* 2>/dev/null || true
    rm -rf "$HOME/.cache/plasmashell/qmlcache"/* 2>/dev/null || true

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

    # Unregister legacy desktop shortcut if present
    if command -v python3 >/dev/null 2>&1; then
        python3 -c '
try:
    import gi
    from gi.repository import Gio, GLib
    bus = Gio.bus_get_sync(Gio.BusType.SESSION, None)
    bus.call_sync("org.kde.kglobalaccel", "/kglobalaccel", "org.kde.KGlobalAccel", "unregister", GLib.Variant("(ss)", ("toggle-raven.desktop", "_launch")), None, Gio.DBusCallFlags.NONE, 1000, None)
except Exception:
    pass
' 2>/dev/null || true
    fi

    # Migrate any live panel widget referencing legacy plugin ID to Nevermore
    local qdbus_tool=""
    if command -v qdbus6 >/dev/null 2>&1; then
        qdbus_tool="qdbus6"
    elif command -v qdbus >/dev/null 2>&1; then
        qdbus_tool="qdbus"
    fi

    if [ -n "$qdbus_tool" ]; then
        "$qdbus_tool" org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript '
        for (let pid of panelIds) {
            let p = panelById(pid);
            if (!p) continue;
            for (let wid of p.widgetIds) {
                let w = p.widgetById(wid);
                if (w && w.type === "org.kde.plasma.budgie.raven") {
                    w.remove();
                    p.addWidget("io.github.berketket.nevermore");
                    print("Migrated panel " + pid + " widget from legacy plugin to io.github.berketket.nevermore");
                }
            }
        }
        ' 2>/dev/null || true
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

    # Register global shortcut Meta+N via org.kde.kglobalaccel D-Bus
    if command -v python3 >/dev/null 2>&1; then
        python3 -c '
try:
    import gi
    from gi.repository import Gio, GLib
    bus = Gio.bus_get_sync(Gio.BusType.SESSION, None)
    action_id = ["toggle-nevermore.desktop", "_launch", "Toggle Nevermore Control Center", "Toggle Nevermore Control Center"]
    bus.call_sync("org.kde.kglobalaccel", "/kglobalaccel", "org.kde.KGlobalAccel", "doRegister", GLib.Variant("(as)", (action_id,)), None, Gio.DBusCallFlags.NONE, 1000, None)
    # Qt::MetaModifier (0x10000000 = 268435456) + Key_N (0x4e = 78) = 268435534
    bus.call_sync("org.kde.kglobalaccel", "/kglobalaccel", "org.kde.KGlobalAccel", "setShortcutKeys", GLib.Variant("(asa(ai)u)", (action_id, [([268435534],)], 2)), None, Gio.DBusCallFlags.NONE, 1000, None)
    print("✓ Registered global shortcut Meta+N via org.kde.kglobalaccel")
except Exception:
    print("Notice: Automated global shortcut registration skipped (configure Meta+N in System Settings -> Shortcuts).")
' 2>/dev/null || true
    fi

    # Refresh live panels so applets reload cleanly without stuck error states
    local qdbus_tool=""
    if command -v qdbus6 >/dev/null 2>&1; then
        qdbus_tool="qdbus6"
    elif command -v qdbus >/dev/null 2>&1; then
        qdbus_tool="qdbus"
    fi

    if [ -n "$qdbus_tool" ]; then
        "$qdbus_tool" org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript '
        // Ensure right autohide panel has a fresh instance of Nevermore
        for (let pid of panelIds) {
            let p = panelById(pid);
            if (!p || p.location !== "right") continue;
            for (let wid of p.widgetIds) {
                let w = p.widgetById(wid);
                if (w && (w.type === "io.github.berketket.nevermore" || w.type === "org.kde.plasma.budgie.raven")) {
                    w.remove();
                }
            }
            p.addWidget("io.github.berketket.nevermore");
            p.hiding = "autohide";
            print("Refreshed Nevermore on right panel " + pid);
        }

        // Ensure top/horizontal panel has at most one Nevermore compact trigger with Meta+N shortcut
        let topPanel = null;
        let topFound = false;
        for (let pid of panelIds) {
            let p = panelById(pid);
            if (!p || p.location === "right") continue;
            if (!topPanel && p.location === "top") topPanel = p;
            for (let wid of p.widgetIds) {
                let w = p.widgetById(wid);
                if (w && (w.type === "io.github.berketket.nevermore" || w.type === "org.kde.plasma.budgie.raven")) {
                    if (!topFound) {
                        topFound = true;
                        if (w.type === "org.kde.plasma.budgie.raven") {
                            w.remove();
                            let nw = p.addWidget("io.github.berketket.nevermore");
                            if (nw) nw.globalShortcut = "Meta+N";
                        } else {
                            w.globalShortcut = "Meta+N";
                        }
                    } else {
                        w.remove();
                    }
                }
            }
        }
        if (!topFound) {
            let targetPanel = topPanel || (panelIds.length > 0 ? panelById(panelIds[0]) : null);
            if (targetPanel && targetPanel.location !== "right") {
                let nw = targetPanel.addWidget("io.github.berketket.nevermore");
                if (nw) nw.globalShortcut = "Meta+N";
                print("Added Nevermore trigger with Meta+N shortcut to panel " + targetPanel.id);
            }
        }
        ' 2>/dev/null || true
        echo "✓ Synchronized live desktop panel applets"
    fi

    # Clear QML cache and restart plasma-plasmashell to force reload of fresh bytecode
    rm -rf "$HOME/.cache/plasmashell/qmlcache"/* 2>/dev/null || true
    if command -v systemctl >/dev/null 2>&1; then
        systemctl --user stop "app-plasmashell@*.service" 2>/dev/null || true
        systemctl --user restart plasma-plasmashell.service 2>/dev/null || true
        sleep 3
        echo "✓ Restarted plasma-plasmashell.service"
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

        # Unregister global shortcut via org.kde.kglobalaccel D-Bus
        if command -v python3 >/dev/null 2>&1; then
            python3 -c '
try:
    import gi
    from gi.repository import Gio, GLib
    bus = Gio.bus_get_sync(Gio.BusType.SESSION, None)
    bus.call_sync("org.kde.kglobalaccel", "/kglobalaccel", "org.kde.KGlobalAccel", "unregister", GLib.Variant("(ss)", ("toggle-nevermore.desktop", "_launch")), None, Gio.DBusCallFlags.NONE, 1000, None)
    print("✓ Unregistered global shortcut via org.kde.kglobalaccel")
except Exception:
    pass
' 2>/dev/null || true
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
