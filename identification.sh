#!/usr/bin/env bash
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "Run with sudo."
  exit 1
fi

CONFIG="/etc/nixos/configuration.nix"
SAKURA_DIR="/etc/nixos/sakura"
MODULE="$SAKURA_DIR/system.nix"

BACKUP="/etc/nixos/configuration.nix.bak.$(date +%s)"

mkdir -p "$SAKURA_DIR"

echo "Backing up configuration.nix..."
cp "$CONFIG" "$BACKUP"

echo "Writing Sakura module..."

cat > "$MODULE" <<'EOF'
{ config, pkgs, lib, ... }:

let
  wallpaper = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/Duckycel/SakuraBRP/main/background.png";
    sha256 = lib.fakeSha256;
  };

  startIcon = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/Duckycel/SakuraBRP/main/logo.png";
    sha256 = lib.fakeSha256;
  };
in
{

  networking.hostName = "sakura";

  environment.systemPackages = with pkgs; [
    fastfetch
    curl
    wget
    feh
  ];

  environment.etc."sakura/background.png".source = wallpaper;

  environment.etc."xdg/icons/hicolor/scalable/apps/start-here.svg".source = startIcon;

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

  systemd.user.services.set-wallpaper = {
    description = "Set Sakura wallpaper";

    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.plasma-workspace}/bin/plasma-apply-wallpaperimage /etc/sakura/background.png";
    };

    wantedBy = [ "graphical-session.target" ];
  };

}
EOF

echo "Checking Sakura import..."

if grep -q "./sakura/system.nix" "$CONFIG"; then
  echo "Import already exists."
else
  echo "Adding Sakura import..."

  sed -i '/imports *= *\[/a\      ./sakura/system.nix' "$CONFIG"
fi

echo "Creating Fastfetch config..."

USER_HOME=$(eval echo "~$SUDO_USER")

mkdir -p "$USER_HOME/.config/fastfetch"

cat > "$USER_HOME/.config/fastfetch/ascii.txt" <<'EOF'
          .-.
       .-(   )-.
      /   Sakura \
     |  🌸  OS   |
      \         /
       `-.___.-'
EOF

cat > "$USER_HOME/.config/fastfetch/config.jsonc" <<'EOF'
{
  "logo": {
    "type": "file",
    "source": "~/.config/fastfetch/ascii.txt"
  },

  "modules": [
    "title",
    "separator",
    "os",
    "host",
    "kernel",
    "uptime",
    "packages",
    "shell",
    "de",
    "wm",
    "terminal",
    "cpu",
    "gpu",
    "memory",
    "disk",
    "localip",
    "battery",
    "locale"
  ]
}
EOF

chown -R "$SUDO_USER":"$SUDO_USER" "$USER_HOME/.config"

echo "Rebuilding system..."

if nixos-rebuild switch; then
  echo "Build successful"
else
  echo "Build failed, restoring backup"
  cp "$BACKUP" "$CONFIG"
  exit 1
fi

echo
echo "=================================="
echo " Sakura OS branding installed 🌸"
echo "=================================="
echo
echo "Hostname: sakura"
echo "Fastfetch configured"
echo "Wallpaper auto-applies on login"
echo "Start menu icon installed"
echo
echo "Log out and back in to see changes."
