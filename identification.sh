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

  # Store wallpaper in the Nix store and link it
  environment.etc."sakura/background.png".source = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/Duckycel/SakuraBRP/main/background.png";
    sha256 = lib.fakeSha256;
  };

  environment.etc."os-release".text = lib.mkForce ''
NAME="Sakura"
PRETTY_NAME="Sakura OS 0.1 RELEASE (Elite)"
ID="sakura"
VERSION_ID="0.1"
VERSION="0.1 RELEASE (Elite)"
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

echo "Checking if Sakura import exists..."

if grep -q "./sakura/system.nix" "$CONFIG"; then
  echo "Import already exists."
else
  echo "Adding Sakura import..."

  sed -i '/imports *= *\[/a\      ./sakura/system.nix' "$CONFIG"
fi

echo "Rebuilding NixOS..."

if nixos-rebuild switch; then
  echo "Build succeeded."
else
  echo "Build failed. Restoring backup."
  cp "$BACKUP" "$CONFIG"
  exit 1
fi

echo
echo "================================="
echo " Sakura OS Installed 🌸"
echo "================================="
echo
echo "Hostname set to: sakura"
echo "Fastfetch installed permanently"
echo "Wallpaper stored at:"
echo "/etc/sakura/background.png"
echo
echo "Set it in KDE once and it will persist."
