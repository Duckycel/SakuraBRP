#!/usr/bin/env bash
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "Run with sudo."
  exit 1
fi

CONFIG="/etc/nixos/configuration.nix"
SAKURA_DIR="/etc/nixos/sakura"
SYSTEM_NIX="$SAKURA_DIR/system.nix"
WALL_SCRIPT="$SAKURA_DIR/set-wallpaper.sh"

TIMESTAMP="$(date +%s)"
BACKUP="/etc/nixos/configuration.nix.bak.$TIMESTAMP"

mkdir -p "$SAKURA_DIR"

echo "Creating Sakura system module..."

cat > "$SYSTEM_NIX" <<'EOF'
{ config, pkgs, lib, ... }:

let
  sakuraWallpaper = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/Duckycel/SakuraBRP/main/background.png";
    sha256 = "0000000000000000000000000000000000000000000000000000";
  };
in
{
  networking.hostName = "sakura";

  environment.systemPackages = with pkgs; [
    fastfetch
    feh
    curl
    wget
  ];

  environment.etc."sakura-wallpaper.png".source = sakuraWallpaper;

  environment.etc."os-release".text = lib.mkForce ''
    NAME="Sakura"
    PRETTY_NAME="Sakura OS 0.1 RELEASE (Elite)"
    ID="sakura"
    VERSION_ID="0.1"
    VERSION="0.1 RELEASE (Elite)"
    VERSION_CODENAME="Elite"
    BUILD_ID="0.1"
    VARIANT="Elite"
    VARIANT_ID="elite"
    ANSI_COLOR="0;35"
    HOME_URL="https://github.com/Duckycel/SakuraBRP"
    SUPPORT_URL="https://github.com/Duckycel/SakuraBRP/issues"
    BUG_REPORT_URL="https://github.com/Duckycel/SakuraBRP/issues"
    DEFAULT_HOSTNAME="sakura"
  '';
}
EOF

echo "Creating KDE wallpaper script..."

cat > "$WALL_SCRIPT" <<'EOF'
#!/usr/bin/env bash

sleep 3

qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "
var Desktops = desktops();
for (i=0;i<Desktops.length;i++) {
  d = Desktops[i];
  d.wallpaperPlugin = 'org.kde.image';
  d.currentConfigGroup = Array('Wallpaper','org.kde.image','General');
  d.writeConfig('Image','file:///etc/sakura-wallpaper.png');
}
"
EOF

chmod +x "$WALL_SCRIPT"

echo "Backing up configuration.nix..."
cp "$CONFIG" "$BACKUP"

echo "Removing duplicate Sakura imports..."

grep -v "./sakura/system.nix" "$CONFIG" > "$CONFIG.tmp"
mv "$CONFIG.tmp" "$CONFIG"

echo "Adding Sakura import..."

awk '
BEGIN {added=0}
/imports *= *\[/ {
  print
  print "      ./sakura/system.nix"
  added=1
  next
}
{print}
END {
 if (added==0) {
   print "ERROR: Could not find imports block."
   exit 1
 }
}
' "$CONFIG" > "$CONFIG.tmp"

mv "$CONFIG.tmp" "$CONFIG"

echo "Rebuilding NixOS..."

nixos-rebuild switch

echo "Setting wallpaper..."

sudo -u "${SUDO_USER:-$USER}" "$WALL_SCRIPT" || true

echo
echo "======================================="
echo " Sakura OS setup complete 🌸"
echo "======================================="
echo
echo "Hostname: sakura"
echo "Fastfetch installed"
echo "Wallpaper applied"
echo
echo "Logout/login if wallpaper didn't update."
