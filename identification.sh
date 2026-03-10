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

echo "Backing up configuration.nix"
cp "$CONFIG" "$BACKUP"

echo "Writing Sakura system module..."

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
    ANSI_COLOR="0;35"
    BUG_REPORT_URL="https://github.com/Duckycel/SakuraBRP/issues"
    BUILD_ID="0.1"
    CPE_NAME="cpe:/o:sakura:sakura_os:0.1"
    DEFAULT_HOSTNAME="sakura"
    HOME_URL="https://github.com/Duckycel/SakuraBRP"
    ID="sakura"
    ID_LIKE=""
    IMAGE_ID="sakura"
    IMAGE_VERSION="0.1"
    LOGO="sakura"
    NAME="Sakura"
    PRETTY_NAME="Sakura OS 0.1 RELEASE (Elite)"
    SUPPORT_END="2026-06-30"
    SUPPORT_URL="https://github.com/Duckycel/SakuraBRP/issues"
    VARIANT="Elite"
    VARIANT_ID="elite"
    VENDOR_NAME="Sakura Project"
    VENDOR_URL="https://github.com/Duckycel/SakuraBRP"
    VERSION="0.1 RELEASE (Elite)"
    VERSION_CODENAME="Elite"
    VERSION_ID="0.1"
  '';
}
EOF

echo "Fixing imports safely..."

# remove duplicate sakura imports blocks
sed -i '/imports = \[/,/];/ {
  /sakura\/system.nix/ {
    :a
    N
    /];/!ba
    d
  }
}' "$CONFIG"

# add sakura/system.nix under hardware import if missing
if ! grep -q "./sakura/system.nix" "$CONFIG"; then
  sed -i '/hardware-configuration.nix/a\      ./sakura/system.nix' "$CONFIG"
fi

echo "Rebuilding NixOS..."
nixos-rebuild switch

echo
echo "SakuraOS bootstrap complete."
echo "Backup saved to $BACKUP"
