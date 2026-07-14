#!/usr/bin/env bash
set -euo pipefail

WITH_DEPS=0
SETUP_HYPRLAND=1
START_DOCK=1

for arg in "$@"; do
  case "$arg" in
    --with-deps) WITH_DEPS=1 ;;
    --no-hyprland) SETUP_HYPRLAND=0 ;;
    --no-start) START_DOCK=0 ;;
    -h|--help)
      cat <<'EOF'
Usage: ./install.sh [--with-deps] [--no-hyprland] [--no-start]

Options:
  --with-deps    Install GTK3/GtkLayerShell dependencies.
  --no-hyprland  Do not write Hyprland integration files.
  --no-start     Do not start the Dock after installation.
EOF
      exit 0
      ;;
    *)
      echo "Unknown option: $arg" >&2
      exit 2
      ;;
  esac
done

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DOCK="$SCRIPT_DIR/bin/villode-dock"
SOURCE_PREVIEW="$SCRIPT_DIR/bin/villode-drag-preview"
SOURCE_ICONS="$SCRIPT_DIR/assets/dock-icons"
INSTALL_DOCK="$HOME/.local/bin/villode-dock"
INSTALL_PREVIEW="$HOME/.local/bin/villode-drag-preview"
INSTALL_ICONS="$HOME/.local/share/villode-dock/icons"
HYPR_DIR="$HOME/.config/hypr"
HYPR_MAIN="$HYPR_DIR/hyprland.conf"
HYPR_INCLUDE_DIR="$HYPR_DIR/conf.d"
HYPR_INCLUDE="$HYPR_INCLUDE_DIR/villode-dock.conf"

need_cmd() {
  command -v "$1" >/dev/null 2>&1
}

check_deps() {
  python3 - <<'PY' >/dev/null 2>&1
import cairo
import gi
gi.require_version("Gdk", "3.0")
gi.require_version("GdkPixbuf", "2.0")
gi.require_version("Gio", "2.0")
gi.require_version("Gtk", "3.0")
gi.require_version("GtkLayerShell", "0.1")
gi.require_version("Pango", "1.0")
from gi.repository import Gdk, GdkPixbuf, Gio, Gtk, GtkLayerShell, Pango
PY
}

install_deps() {
  if need_cmd pacman; then
    sudo pacman -S --needed python python-gobject python-cairo gtk3 gtk-layer-shell
  elif need_cmd apt; then
    sudo apt update
    sudo apt install -y python3 python3-gi python3-cairo \
      gir1.2-gtk-3.0 gir1.2-gtk-layer-shell-0.1
  elif need_cmd dnf; then
    sudo dnf install -y python3 python3-gobject python3-cairo gtk3 gtk-layer-shell
  elif need_cmd zypper; then
    sudo zypper install -y python3 python3-gobject python3-cairo gtk3 gtk-layer-shell
  else
    echo "No supported package manager found. Install GTK3, GtkLayerShell and Python bindings manually." >&2
    return 1
  fi
}

write_hyprland_config() {
  mkdir -p "$HYPR_INCLUDE_DIR"
  cat > "$HYPR_INCLUDE" <<'EOF'
# Villode Dock
$dock = villode-dock

exec-once = villode-dock --daemon

layerrule = blur true, match:namespace villode-dock
layerrule = ignore_alpha 0.12, match:namespace villode-dock
layerrule = xray false, match:namespace villode-dock
# Context menu / about (glass layer, same blur as the dock panel)
layerrule = blur true, match:namespace villode-dock-menu
layerrule = ignore_alpha 0.12, match:namespace villode-dock-menu
layerrule = xray false, match:namespace villode-dock-menu
layerrule = order 50, match:namespace villode-dock
layerrule = order 60, match:namespace villode-dock-menu
layerrule = order 10, match:namespace caelestia-drawers
EOF

  mkdir -p "$HYPR_DIR"
  touch "$HYPR_MAIN"
  # Migrate releases which wrote the Dock block directly into hyprland.conf.
  # The include becomes the single managed source, so upgrades stay idempotent.
  sed -i.bak \
    -e '/^[[:space:]]*#[[:space:]]*Villode Dock[[:space:]]*$/d' \
    -e '/villode-dock\.conf/d' \
    -e '/^[[:space:]]*\$dock[[:space:]]*=[[:space:]]*villode-dock[[:space:]]*$/d' \
    -e '/^[[:space:]]*exec-once[[:space:]]*=.*villode-dock/d' \
    -e '/^[[:space:]]*exec-once[[:space:]]*=.*\$dock/d' \
    -e '/^[[:space:]]*layerrule[[:space:]]*=.*villode-dock/d' \
    "$HYPR_MAIN"
  {
    echo
    echo "# Villode Dock"
    echo "source = ~/.config/hypr/conf.d/villode-dock.conf"
  } >> "$HYPR_MAIN"
}

if [ ! -x "$SOURCE_DOCK" ]; then
  echo "Missing executable: $SOURCE_DOCK" >&2
  exit 1
fi
if [ ! -x "$SOURCE_PREVIEW" ]; then
  echo "Missing executable: $SOURCE_PREVIEW" >&2
  exit 1
fi
if [ ! -d "$SOURCE_ICONS" ]; then
  echo "Missing Dock icons: $SOURCE_ICONS" >&2
  exit 1
fi

if ! check_deps; then
  if [ "$WITH_DEPS" -eq 1 ]; then
    install_deps
  else
    echo "Missing GTK3/GtkLayerShell Python dependencies." >&2
    echo "Run again with: ./install.sh --with-deps" >&2
    exit 1
  fi
fi

mkdir -p "$(dirname "$INSTALL_DOCK")" "$INSTALL_ICONS"
install -m 755 "$SOURCE_DOCK" "$INSTALL_DOCK"
install -m 755 "$SOURCE_PREVIEW" "$INSTALL_PREVIEW"
install -m 644 "$SOURCE_ICONS"/*.png "$INSTALL_ICONS"/
install -m 644 "$SOURCE_ICONS/CREDITS.md" "$INSTALL_ICONS/CREDITS.md"
python3 -m py_compile "$INSTALL_DOCK" "$INSTALL_PREVIEW"

if [ "$SETUP_HYPRLAND" -eq 1 ]; then
  write_hyprland_config
  if need_cmd hyprctl && hyprctl monitors >/dev/null 2>&1; then
    hyprctl reload >/dev/null || true
  fi
fi

if [ "$START_DOCK" -eq 1 ]; then
  "$INSTALL_DOCK" --reload
fi

echo "Installed: $INSTALL_DOCK"
echo "Installed: $INSTALL_PREVIEW"
echo "Dock icons: $INSTALL_ICONS"
if [ "$SETUP_HYPRLAND" -eq 1 ]; then
  echo "Hyprland config: $HYPR_INCLUDE"
fi
if [ "$START_DOCK" -eq 1 ]; then
  echo "Dock started."
fi
