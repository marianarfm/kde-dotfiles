#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APPLY_THEME=0

WALLPAPER_PATH="${HOME}/Pictures/Wallpapers/nord_tux.png"

INSTALL_MAP=(
  ".config/btop:.config/btop"
  ".config/fastfetch:.config/fastfetch"
  ".local/share/aurorae/themes/nordic:.local/share/aurorae/themes/nordic"
  ".local/share/color-schemes/nordic.colors:.local/share/color-schemes/nordic.colors"
  ".local/share/icons/capitaine-cursors-nord:.local/share/icons/capitaine-cursors-nord"
  ".local/share/icons/tela-circle:.local/share/icons/tela-circle"
  ".local/share/icons/tela-circle-dark:.local/share/icons/tela-circle-dark"
  ".local/share/icons/tela-circle-light:.local/share/icons/tela-circle-light"
  ".local/share/konsole/Nord.profile:.local/share/konsole/Nord.profile"
  ".local/share/konsole/nord.colorscheme:.local/share/konsole/nord.colorscheme"
  ".local/share/plasma/desktoptheme/polar-gleam:.local/share/plasma/desktoptheme/polar-gleam"
  "assets/wallpapers/nord_tux.png:Pictures/Wallpapers/nord_tux.png"
)

usage() {
  cat <<'EOF'
Usage: ./install.sh [--apply-theme]
EOF
}

apply_desktop_wallpaper() {
  local script

  read -r -d '' script <<EOF || true
const wallpaper = "file://${WALLPAPER_PATH}";
for (const desktop of desktops()) {
  desktop.wallpaperPlugin = "org.kde.image";
  desktop.currentConfigGroup = ["Wallpaper", "org.kde.image", "General"];
  desktop.writeConfig("Image", wallpaper);
}
EOF

  qdbus6 org.kde.PlasmaShell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$script" >/dev/null
}

apply_theme_settings() {
  command -v kwriteconfig6 >/dev/null 2>&1 || { echo "Missing required command: kwriteconfig6"; exit 1; }
  command -v plasma-apply-colorscheme >/dev/null 2>&1 || { echo "Missing required command: plasma-apply-colorscheme"; exit 1; }
  command -v plasma-apply-desktoptheme >/dev/null 2>&1 || { echo "Missing required command: plasma-apply-desktoptheme"; exit 1; }
  command -v qdbus6 >/dev/null 2>&1 || { echo "Missing required command: qdbus6"; exit 1; }

  [[ -e "$WALLPAPER_PATH" ]] || { echo "Wallpaper not found at ${WALLPAPER_PATH}"; exit 1; }

  echo "Applying KDE settings"
  plasma-apply-colorscheme nordic
  plasma-apply-desktoptheme Polar-Gleam
  kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --group Windeco --key library org.kde.kwin.aurorae
  kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --group Windeco --key theme Nordic
  kwriteconfig6 --file kdeglobals --group Icons --key Theme Tela-circle-dark
  kwriteconfig6 --file kcminputrc --group Mouse --key cursorTheme "Capitaine Cursors (Nord)"
  kwriteconfig6 --file kcminputrc --group Mouse --key cursorSize 32
  kwriteconfig6 --file konsolerc --group Desktop Entry --key DefaultProfile Nord.profile
  apply_desktop_wallpaper
  kwriteconfig6 --file kscreenlockerrc --group Greeter --group Wallpaper --group org.kde.image --group General --key Image "${WALLPAPER_PATH}"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --apply-theme)
      APPLY_THEME=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      usage
      exit 1
      ;;
  esac
  shift
done

echo "Installing dotfiles into ${HOME}"

for entry in "${INSTALL_MAP[@]}"; do
  source="${SCRIPT_DIR}/${entry%%:*}"
  target="${HOME}/${entry#*:}"

  if [[ ! -e "$source" && ! -L "$source" ]]; then
    echo "Skipping missing source ${source}"
    continue
  fi

  if [[ -e "$target" || -L "$target" ]]; then
    echo "Removing ${target}"
    rm -rf "$target"
  fi

  mkdir -p "$(dirname "$target")"

  echo "Copying ${source} -> ${target}"
  cp -a "$source" "$target"
done

if (( APPLY_THEME )); then
  apply_theme_settings
fi

echo "Install complete."
