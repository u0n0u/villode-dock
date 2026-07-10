#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DOCK="$SCRIPT_DIR/bin/villode-dock"
ICON_SOURCE="$SCRIPT_DIR/assets/dock-icons"
ICON_TARGET="$HOME/.local/share/villode-dock/icons"

python3 -m py_compile "$DOCK"
mkdir -p "$ICON_TARGET"
install -m 644 "$ICON_SOURCE"/*.png "$ICON_TARGET"/
install -m 644 "$ICON_SOURCE/CREDITS.md" "$ICON_TARGET/CREDITS.md"
"$DOCK" --reload
