#!/usr/bin/env bash
set -euo pipefail

BASE="$HOME/Sakura"
MANDATORY="$BASE/MandatoryPackages"
SETTINGS="$MANDATORY/Settings"
THEME="$SETTINGS/theme.sh"

mkdir -p "$SETTINGS"

cat > "$THEME" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

if command -v kwriteconfig6 >/dev/null 2>&1; then
    KWRITE="kwriteconfig6"
elif command -v kwriteconfig5 >/dev/null 2>&1; then
    KWRITE="kwriteconfig5"
else
    echo "kwriteconfig not found"
    exit 1
fi

"$KWRITE" --file kdeglobals --group General --key ColorScheme "BreezeDark"
"$KWRITE" --file kdeglobals --group KDE --key widgetStyle "Breeze"
"$KWRITE" --file kdeglobals --group Icons --key Theme "breeze-dark"
"$KWRITE" --file plasmarc --group Theme --key name "default"
"$KWRITE" --file kwinrc --group org.kde.kdecoration2 --key theme "Breeze"
"$KWRITE" --file kwinrc --group Plugins --key blurEnabled true
"$KWRITE" --file kwinrc --group Plugins --key translucencyEnabled true
"$KWRITE" --file kwinrc --group Compositing --key Enabled true

if command -v qdbus6 >/dev/null 2>&1; then
    qdbus6 org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true
elif command -v qdbus >/dev/null 2>&1; then
    qdbus org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true
fi

pkill plasmashell >/dev/null 2>&1 || true
nohup plasmashell >/dev/null 2>&1 &
EOF

chmod +x "$THEME"

nix-shell -p kdePackages.kconfig kdePackages.kdbusaddons kdePackages.plasma-workspace kdePackages.kwin qt6.qttools --run "$THEME"
