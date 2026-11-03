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

# Locate Nevermore widget ID across active Plasma panels and activate it.
# Activating the widget toggles its native Plasma popup Dialog with ZERO struts (no window shifting).
# Prefer compact/horizontal panel instance (e.g. top panel) so Meta+N always triggers zero-strut popup overlay.
WIDGET_ID=$("$QDBUS_BIN" org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript '
let targetId = "";
// First pass: prefer compact trigger instance on top or horizontal panel
for (let pid of panelIds) {
    let p = panelById(pid);
    if (!p || p.location === "right") continue;
    for (let wid of p.widgetIds) {
        let w = p.widgetById(wid);
        if (w && w.type === "io.github.berketket.nevermore") {
            targetId = wid;
            break;
        }
    }
    if (targetId !== "") break;
}
// Fallback pass: any panel if no horizontal instance exists
if (targetId === "") {
    for (let pid of panelIds) {
        let p = panelById(pid);
        if (!p) continue;
        for (let wid of p.widgetIds) {
            let w = p.widgetById(wid);
            if (w && w.type === "io.github.berketket.nevermore") {
                targetId = wid;
                break;
            }
        }
        if (targetId !== "") break;
    }
}
print(targetId);
' 2>/dev/null || true)

WIDGET_ID="$(echo "$WIDGET_ID" | tr -d '[:space:]')"

if [ -n "$WIDGET_ID" ]; then
    "$QDBUS_BIN" org.kde.kglobalaccel /component/plasmashell org.kde.kglobalaccel.Component.invokeShortcut "activate widget $WIDGET_ID"
    echo "Toggled Nevermore widget $WIDGET_ID overlay with zero struts"
else
    # Fallback to toggling right autohide panel if applet not found
    "$QDBUS_BIN" org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript '
    for (let id of panelIds) {
        let p = panelById(id);
        if (p && p.location === "right") {
            p.hiding = (p.hiding === "autohide" ? "none" : "autohide");
            print("Toggled Nevermore panel " + id + " to " + p.hiding);
            break;
        }
    }
    ' 2>/dev/null || true
fi
