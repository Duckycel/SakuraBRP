#!/usr/bin/env bash
set -euo pipefail

if ! command -v nix-env >/dev/null 2>&1; then
    echo "nix-env not found"
    exit 1
fi

nix-env -iA \
    nixos.kdePackages.kconfig \
    nixos.kdePackages.kdbusaddons \
    nixos.kdePackages.plasma-workspace \
    nixos.kdePackages.kwin \
    nixos.qt6.qttools

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
"$KWRITE" --file kwinrc --group Compositing --key Backend OpenGL
"$KWRITE" --file kwinrc --group Compositing --key GLCore true

if command -v qdbus6 >/dev/null 2>&1; then
    qdbus6 org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true
elif command -v qdbus >/dev/null 2>&1; then
    qdbus org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true
fi

if command -v kquitapp6 >/dev/null 2>&1; then
    kquitapp6 plasmashell >/dev/null 2>&1 || true
elif command -v kquitapp5 >/dev/null 2>&1; then
    kquitapp5 plasmashell >/dev/null 2>&1 || true
elif command -v kquitapp >/dev/null 2>&1; then
    kquitapp plasmashell >/dev/null 2>&1 || true
else
    pkill plasmashell >/dev/null 2>&1 || true
fi

sleep 1

if command -v kstart6 >/dev/null 2>&1; then
    nohup kstart6 plasmashell >/dev/null 2>&1 &
elif command -v kstart5 >/dev/null 2>&1; then
    nohup kstart5 plasmashell >/dev/null 2>&1 &
elif command -v kstart >/dev/null 2>&1; then
    nohup kstart plasmashell >/dev/null 2>&1 &
elif command -v plasmashell >/dev/null 2>&1; then
    nohup plasmashell >/dev/null 2>&1 &
fi
EOF

chmod +x "$THEME"
"$THEME"
