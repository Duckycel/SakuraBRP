#!/usr/bin/env bash
set -euo pipefail

BASE="$HOME/Sakura"
MANDATORY="$BASE/MandatoryPackages"
SETTINGS="$MANDATORY/Settings"
THEME="$SETTINGS/theme.sh"

mkdir -p "$SETTINGS"

if [ ! -f "$THEME" ]; then
cat > "$THEME" <<'EOF'
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
chmod +x "$THEME"
fi
