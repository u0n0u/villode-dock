#!/usr/bin/env bash
set -euo pipefail

PURGE=0
for arg in "$@"; do
  case "$arg" in
    --purge) PURGE=1 ;;
    -h|--help)
      cat <<'EOF'
Usage: ./uninstall.sh [--purge]

Options:
  --purge  Also remove ~/.config/villode-dock data.
EOF
      exit 0
      ;;
    *)
      echo "Unknown option: $arg" >&2
      exit 2
      ;;
  esac
done

"$HOME/.local/bin/villode-dock" --quit >/dev/null 2>&1 || true
rm -f "$HOME/.local/bin/villode-dock"
rm -f "$HOME/.local/bin/villode-drag-preview"
rm -rf "$HOME/.local/share/villode-dock"
rm -f "$HOME/.cache/villode-dock.pid"
rm -f "$HOME/.cache/villode-dock.instance.lock"
rm -f "$HOME/.cache/villode-dock.operation.lock"
rm -f "$HOME/.cache/villode-dock-control.sock"
rm -f "$HOME/.config/hypr/conf.d/villode-dock.conf"

HYPR_MAIN="$HOME/.config/hypr/hyprland.conf"
if [ -f "$HYPR_MAIN" ]; then
  sed -i.bak \
    -e '/^[[:space:]]*#[[:space:]]*Villode Dock[[:space:]]*$/d' \
    -e '/villode-dock\.conf/d' \
    -e '/^[[:space:]]*\$dock[[:space:]]*=[[:space:]]*villode-dock[[:space:]]*$/d' \
    -e '/^[[:space:]]*exec-once[[:space:]]*=.*villode-dock/d' \
    -e '/^[[:space:]]*exec-once[[:space:]]*=.*\$dock/d' \
    -e '/^[[:space:]]*layerrule[[:space:]]*=.*villode-dock/d' \
    "$HYPR_MAIN"
fi

if [ "$PURGE" -eq 1 ]; then
  rm -rf "$HOME/.config/villode-dock"
fi

if command -v hyprctl >/dev/null 2>&1 && hyprctl monitors >/dev/null 2>&1; then
  hyprctl reload >/dev/null || true
fi

echo "Uninstalled Villode Dock."
