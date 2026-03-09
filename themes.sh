#!/usr/bin/env bash
set -euo pipefail

echo "Applying SakuraOS desktop tweaks..."

# Enable KDE Dark Mode
kwriteconfig5 --file kdeglobals --group General --key ColorScheme "BreezeDark"
kwriteconfig5 --file kdeglobals --group KDE --key widgetStyle "Breeze"
kwriteconfig5 --file kdeglobals --group Icons --key Theme "breeze-dark"

# Set Plasma theme
kwriteconfig5 --file plasmarc --group Theme --key name "default"

# Window decoration theme
kwriteconfig5 --file kwinrc --group org.kde.kdecoration2 --key theme "Breeze"

# Enable transparency / blur effects
kwriteconfig5 --file kwinrc --group Plugins --key blurEnabled true
kwriteconfig5 --file kwinrc --group Plugins --key translucencyEnabled true

# Ensure compositor is enabled
kwriteconfig5 --file kwinrc --group Compositing --key Enabled true
kwriteconfig5 --file kwinrc --group Compositing --key Backend OpenGL
kwriteconfig5 --file kwinrc --group Compositing --key GLCore true

# Reload KWin
qdbus org.kde.KWin /KWin reconfigure || true

# Restart Plasma shell
kquitapp5 plasmashell || true
kstart5 plasmashell || true

echo "Dark mode and transparency enabled."
echo "You may need to log out and back in for full effect."
