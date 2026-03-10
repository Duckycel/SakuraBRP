#!/usr/bin/env bash

set -euo pipefail

USER_NAME="$(whoami)"
HOME_DIR="$HOME"
SAKURA_DIR="$HOME_DIR/Sakura"
IDENT_DIR="$SAKURA_DIR/MandatoryPackages/Identification"
ASSETS_DIR="$IDENT_DIR/Assets"
FASTFETCH_DIR="$HOME_DIR/.config/fastfetch"
FASTFETCH_CONFIG="$FASTFETCH_DIR/config.jsonc"
ASCII_FILE="$FASTFETCH_DIR/ascii.txt"
NIXOS_CONFIG="/etc/nixos/configuration.nix"

BACKGROUND_FILE="$ASSETS_DIR/background.png"
BOOT_LOGO_FILE="$ASSETS_DIR/logo.png"
WHITE_LOGO_FILE="$ASSETS_DIR/whitelogo.png"

BACKGROUND_URL="https://raw.githubusercontent.com/Duckycel/SakuraBRP/main/background.png"
BOOT_LOGO_URL="https://raw.githubusercontent.com/Duckycel/SakuraBRP/main/logo.png"
WHITE_LOGO_URL="https://raw.githubusercontent.com/Duckycel/SakuraBRP/main/whitelogo.png"

echo "Setting up Sakura OS identification..."

mkdir -p "$IDENT_DIR"
mkdir -p "$ASSETS_DIR"
mkdir -p "$FASTFETCH_DIR"

download_file() {
    local url="$1"
    local out="$2"

    echo "Downloading $(basename "$out")..."
    if command -v wget >/dev/null 2>&1; then
        wget -O "$out" "$url"
    elif command -v curl >/dev/null 2>&1; then
        curl -L "$url" -o "$out"
    else
        echo "Neither wget nor curl is installed."
        echo "Run this script with: nix-shell -p wget --run \"wget -O identification.sh <url> && chmod +x identification.sh && sudo ./identification.sh\""
        exit 1
    fi
}

ensure_fastfetch_persistent() {
    if [ "$(id -u)" -ne 0 ]; then
        echo "Not running as root, cannot make fastfetch permanent."
        return
    fi

    if [ ! -f "$NIXOS_CONFIG" ]; then
        echo "Could not find $NIXOS_CONFIG"
        return
    fi

    echo "Ensuring fastfetch is installed permanently through configuration.nix..."

    if grep -q 'fastfetch' "$NIXOS_CONFIG"; then
        echo "fastfetch already appears in configuration.nix"
    else
        python3 <<'PY'
from pathlib import Path
path = Path("/etc/nixos/configuration.nix")
text = path.read_text()

if "environment.systemPackages = with pkgs; [" in text:
    text = text.replace(
        "environment.systemPackages = with pkgs; [",
        "environment.systemPackages = with pkgs; [\n    fastfetch",
        1
    )
else:
    block = """

  # SakuraOS mandatory packages
  environment.systemPackages = with pkgs; [
    fastfetch
  ];
"""
    if text.rstrip().endswith("}"):
        text = text.rstrip()[:-1] + block + "\n}\n"
    else:
        text += block

path.write_text(text)
PY
        echo "Added fastfetch to configuration.nix"
    fi

    echo "Running nixos-rebuild switch..."
    nixos-rebuild switch
}

install_temp_pkg_if_missing() {
    local pkg="$1"
    if ! command -v "$pkg" >/dev/null 2>&1; then
        echo "$pkg not found."
        echo "Trying temporary install with nix-env..."
        nix-env -iA "nixpkgs.$pkg" || true
    fi
}

install_temp_pkg_if_missing curl
install_temp_pkg_if_missing wget
install_temp_pkg_if_missing feh
install_temp_pkg_if_missing fastfetch

if [ "$(id -u)" -eq 0 ]; then
    ensure_fastfetch_persistent
else
    echo "Tip: run with sudo so fastfetch can be added permanently to configuration.nix"
fi

download_file "$BACKGROUND_URL" "$BACKGROUND_FILE"
download_file "$BOOT_LOGO_URL" "$BOOT_LOGO_FILE"
download_file "$WHITE_LOGO_URL" "$WHITE_LOGO_FILE"

echo "Writing Fastfetch ASCII..."
cat > "$ASCII_FILE" <<'EOF'
                                           
                                 @@% #     
                                @# ##*     
                  @-#@@ @@       ###       
                 @@ ##% @@@        %####*  
                @@@ @@@ @@@@       *.#+*%  
          @@@@@ @ @ @@@ @@:@@@@@@@         
        @+#    @@@* @@@. #@@@ %%   @       
       @-=- @@      @@@.=- .:   .@#@       
       @.#%@@@@@@@=@@.#@@@@@@@@@@##%@      
        @%*###%@@@@=@.@@:@@@%####*+@       
 *+*+:#   @@#*@  #  @%+-  :@@%+=@@         
   #%##:   @@ #..@@ @@@ @@@  .#@           
           @.:@@@@@ %%% @@@@@@  @          
      @@.* %@@@@@@@ #@@ @@@@@@@@@          
     @ ###  @@#@@@@@@  @@@@@@ @@           
               @@@        @@@              
EOF

echo "Writing Fastfetch config..."
cat > "$FASTFETCH_CONFIG" <<EOF
{
  "logo": {
    "type": "file",
    "source": "$ASCII_FILE"
  },
  "display": {
    "separator": "  "
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

echo "Applying wallpaper..."
if command -v feh >/dev/null 2>&1; then
    feh --bg-fill "$BACKGROUND_FILE" || true
fi

echo "Writing /etc/os-release..."
if [ "$(id -u)" -eq 0 ]; then
    rm -f /etc/os-release 2>/dev/null || true

    if touch /etc/os-release 2>/dev/null; then
        cat > /etc/os-release <<'EOF'
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
EOF
        echo "Wrote /etc/os-release"
    else
        echo "Could not write /etc/os-release on this NixOS setup, skipping."
    fi
else
    echo "Not running as root, so /etc/os-release was not changed."
fi

echo "Setting hostname..."
if [ "$(id -u)" -eq 0 ]; then
    hostnamectl set-hostname sakura || true
fi

echo
echo "Done."
echo "Background: $BACKGROUND_FILE"
echo "Boot logo:  $BOOT_LOGO_FILE"
echo "White logo: $WHITE_LOGO_FILE"
echo "Fastfetch:  $FASTFETCH_CONFIG"
