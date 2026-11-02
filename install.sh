#!/usr/bin/env bash
set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLASMOID_DIR="$HOME/.local/share/plasma/plasmoids/org.kde.plasma.budgie.raven"
BIN_DIR="$HOME/.local/bin"
APP_DIR="$HOME/.local/share/applications"

echo "=== Installing Nevermore Control Center ==="

mkdir -p "$BIN_DIR" "$APP_DIR" "$(dirname "$PLASMOID_DIR")"

# Link or copy plasmoid
if [ -d "$PLASMOID_DIR" ] && [ ! -L "$PLASMOID_DIR" ]; then
    echo "Backing up existing plasmoid..."
    mv "$PLASMOID_DIR" "${PLASMOID_DIR}.bak.$(date +%s)"
fi

rm -rf "$PLASMOID_DIR"
ln -sfn "$REPO_DIR" "$PLASMOID_DIR"
echo "✓ Symlinked plasmoid to $PLASMOID_DIR"

# Install toggle script
cp "$REPO_DIR/scripts/toggle-raven.sh" "$BIN_DIR/toggle-raven.sh"
chmod +x "$BIN_DIR/toggle-raven.sh"
echo "✓ Installed toggle script to $BIN_DIR/toggle-raven.sh"

# Install desktop entry
cp "$REPO_DIR/scripts/toggle-raven.desktop" "$APP_DIR/toggle-raven.desktop"
echo "✓ Installed desktop entry to $APP_DIR/toggle-raven.desktop"

# Rebuild sycoca
kbuildsycoca6 >/dev/null 2>&1 || true

echo "=== Nevermore installed successfully! ==="
echo "Restart plasmashell or use Super + N to toggle."
