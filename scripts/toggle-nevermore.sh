#!/usr/bin/env bash
set -euo pipefail

QDBUS_BIN=""
if command -v qdbus6 >/dev/null 2>&1; then
    QDBUS_BIN="qdbus6"
elif command -v qdbus >/dev/null 2>&1; then
    QDBUS_BIN="qdbus"
else
    echo "Error: Neither 'qdbus6' nor 'qdbus' command was found in PATH." >&2
    echo "Please install qt6-tools or qt5-tools to enable D-Bus scripting." >&2
    exit 1
fi

"$QDBUS_BIN" org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript '
for (let id of panelIds) {
    let p = panelById(id);
    if (p && p.location === "right") {
        p.hiding = (p.hiding === "autohide" ? "none" : "autohide");
        print("Toggled Nevermore panel " + id + " to " + p.hiding);
        break;
    }
}
'
