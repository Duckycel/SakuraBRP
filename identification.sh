#!/usr/bin/env bash
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "Run with sudo."
  exit 1
fi

CONFIG="/etc/nixos/configuration.nix"
SAKURA_DIR="/etc/nixos/sakura"
SYSTEM_NIX="$SAKURA_DIR/system.nix"
BACKUP="/etc/nixos/configuration.nix.bak.$(date +%s)"

mkdir -p "$SAKURA_DIR"

echo "Backing up configuration.nix..."
cp "$CONFIG" "$BACKUP"

echo "Creating Sakura module..."

cat > "$SYSTEM_NIX" <<'EOF'
{ config, pkgs, lib, ... }:

{
  networking.hostName = "sakura";

  environment.systemPackages = with pkgs; [
    fastfetch
    feh
    curl
    wget
  ];

  environment.etc."os-release".text = lib.mkForce ''
NAME="Sakura"
PRETTY_NAME="Sakura OS 0.1 RELEASE (Elite)"
ID="sakura"
VERSION="0.1 RELEASE (Elite)"
VERSION_ID="0.1"
VERSION_CODENAME="Elite"
VARIANT="Elite"
VARIANT_ID="elite"
BUILD_ID="0.1"
ANSI_COLOR="0;35"
HOME_URL="https://github.com/Duckycel/SakuraBRP"
SUPPORT_URL="https://github.com/Duckycel/SakuraBRP/issues"
BUG_REPORT_URL="https://github.com/Duckycel/SakuraBRP/issues"
DEFAULT_HOSTNAME="sakura"
'';
}
EOF

echo "Checking if Sakura import already exists..."

if grep -q "./sakura/system.nix" "$CONFIG"; then
  echo "Sakura import already present. Skipping."
else
  echo "Adding Sakura import safely..."

  sed -i '/imports = \[/a\      ./sakura/system.nix' "$CONFIG"
fi

echo "Downloading wallpaper..."

mkdir -p /etc/sakura
curl -L https://raw.githubusercontent.com/Duckycel/SakuraBRP/main/background.png \
  -o /etc/sakura/background.png

echo "Creating KDE wallpaper setter..."

cat > /etc/sakura/set-wallpaper.sh <<'EOF'
#!/usr/bin/env bash

sleep 2

qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "
var Desktops = desktops();
for (i=0;i<Desktops.length;i++) {
d = Desktops[i];
d.wallpaperPlugin = 'org.kde.image';
d.currentConfigGroup = Array('Wallpaper','org.kde.image','General');
d.writeConfig('Image','file:///etc/sakura/background.png');
}
"
EOF

chmod +x /etc/sakura/set-wallpaper.sh

echo "Rebuilding NixOS..."

if nixos-rebuild switch; then
  echo "Rebuild successful"
else
  echo "Build failed — restoring backup"
  cp "$BACKUP" "$CONFIG"
  exit 1
fi

echo "Applying wallpaper..."

sudo -u "${SUDO_USER:-$USER}" /etc/sakura/set-wallpaper.sh || true

echo
echo "================================"
echo " Sakura OS installed 🌸"
echo "================================"
echo
echo "Hostname: sakura"
echo "Fastfetch installed"
echo "Wallpaper installed"
echo
echo "Log out and back in if wallpaper didn't update."
