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

install_pkg() {
    local pkg="$1"
    if ! command -v "$pkg" >/dev/null 2>&1; then
        echo "Installing $pkg..."
        nix-env -iA "nixpkgs.$pkg" || echo "Failed to install $pkg"
    else
        echo "$pkg already installed"
    fi
}

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
        exit 1
    fi
}

install_pkg wget
install_pkg curl
install_pkg fastfetch
install_pkg feh

download_file "$BACKGROUND_URL" "$BACKGROUND_FILE"
download_file "$BOOT_LOGO_URL" "$BOOT_LOGO_FILE"
download_file "$WHITE_LOGO_URL" "$WHITE_LOGO_FILE"

echo "Writing fastfetch ASCII..."
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

echo "Writing fastfetch config..."
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
    echo "Not running as root, so /etc/os-release was not changed."
    echo "Run this script with sudo to write the OS identity."
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
