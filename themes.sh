#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$HOME/Sakura"
MANDATORY_DIR="$BASE_DIR/MandatoryPackages"
SETTINGS_DIR="$BASE_DIR/Settings"
THEME_FILE="$SETTINGS_DIR/theme.sh"

mkdir -p "$MANDATORY_DIR" "$SETTINGS_DIR"

if [ ! -f "$THEME_FILE" ]; then
cat > "$THEME_FILE" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

kwriteconfig5 --file kdeglobals --group General --key ColorScheme "BreezeDark"
kwriteconfig5 --file kdeglobals --group KDE --key widgetStyle "Breeze"
kwriteconfig5 --file kdeglobals --group Icons --key Theme "breeze-dark"
kwriteconfig5 --file plasmarc --group Theme --key name "default"
kwriteconfig5 --file kwinrc --group org.kde.kdecoration2 --key theme "Breeze"
kwriteconfig5 --file kwinrc --group Plugins --key blurEnabled true
kwriteconfig5 --file kwinrc --group Plugins --key translucencyEnabled true
kwriteconfig5 --file kwinrc --group Compositing --key Enabled true
kwriteconfig5 --file kwinrc --group Compositing --key Backend OpenGL
kwriteconfig5 --file kwinrc --group Compositing --key GLCore true
qdbus org.kde.KWin /KWin reconfigure || true
kquitapp5 plasmashell || true
kstart5 plasmashell || true
EOF
chmod +x "$THEME_FILE"
fi
