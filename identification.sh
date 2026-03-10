#!/usr/bin/env bash
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "Run with sudo."
  exit 1
fi

CONFIG="/etc/nixos/configuration.nix"
SAKURA_DIR="/etc/nixos/sakura"
SYSTEM_NIX="$SAKURA_DIR/system.nix"
TIMESTAMP="$(date +%s)"
BACKUP="/etc/nixos/configuration.nix.bak.$TIMESTAMP"
TMP="$(mktemp)"
TMP2="$(mktemp)"

mkdir -p "$SAKURA_DIR"

validate_config() {
  nix-instantiate --parse "$CONFIG" >/dev/null 2>&1
}

restore_latest_backup() {
  local latest
  latest="$(ls -1t /etc/nixos/configuration.nix.bak.* 2>/dev/null | head -n 1 || true)"
  if [ -n "$latest" ] && [ -f "$latest" ]; then
    echo "Current configuration.nix is broken."
    echo "Restoring latest backup: $latest"
    cp "$latest" "$CONFIG"
  else
    echo "Current configuration.nix is broken, and no backup was found."
    echo "Please fix /etc/nixos/configuration.nix manually first."
    exit 1
  fi
}

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

echo "Checking existing configuration.nix..."
if ! validate_config; then
  restore_latest_backup
fi

if ! validate_config; then
  echo "configuration.nix is still invalid after restore."
  echo "Please repair it manually, then rerun this script."
  exit 1
fi

echo "Backing up current configuration.nix to $BACKUP"
cp "$CONFIG" "$BACKUP"

echo "Cleaning duplicate Sakura import lines..."
awk '
{
  if ($0 ~ /[.]\/sakura\/system[.]nix/) next
  print
}
' "$CONFIG" > "$TMP"
mv "$TMP" "$CONFIG"

echo "Inserting Sakura import into the main imports block..."
awk '
BEGIN {
  in_imports = 0
  inserted = 0
}
{
  if ($0 ~ /^[[:space:]]*imports[[:space:]]*=/) {
    in_imports = 1
    print
    next
  }

  if (in_imports == 1) {
    if ($0 ~ /^[[:space:]]*\];/) {
      print "      ./sakura/system.nix"
      print
      inserted = 1
      in_imports = 0
      next
    }
    print
    next
  }

  print
}
END {
  if (inserted == 0) {
    exit 2
  }
}
' "$CONFIG" > "$TMP2" || {
  rm -f "$TMP" "$TMP2"
  echo "Could not find an imports block in configuration.nix."
  echo "Add this manually inside your existing imports list:"
  echo "  ./sakura/system.nix"
  exit 1
}
mv "$TMP2" "$CONFIG"

echo "Validating edited configuration.nix..."
if ! validate_config; then
  echo "Edited configuration.nix is invalid. Restoring backup."
  cp "$BACKUP" "$CONFIG"
  rm -f "$TMP" "$TMP2"
  exit 1
fi

echo "Rebuilding NixOS..."
nixos-rebuild switch

rm -f "$TMP" "$TMP2"

echo
echo "Done."
echo "Sakura system module written to: $SYSTEM_NIX"
echo "Backup saved to: $BACKUP"
