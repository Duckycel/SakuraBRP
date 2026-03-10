#!/usr/bin/env bash

set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
    echo "Please run this script with sudo."
    exit 1
fi

REAL_USER="${SUDO_USER:-$(logname 2>/dev/null || echo root)}"
REAL_HOME="$(getent passwd "$REAL_USER" | cut -d: -f6)"

if [ -z "${REAL_HOME:-}" ]; then
    REAL_HOME="/home/$REAL_USER"
fi

SAKURA_DIR="$REAL_HOME/Sakura"
IDENT_DIR="$SAKURA_DIR/MandatoryPackages/Identification"
ASSETS_DIR="$IDENT_DIR/Assets"
FASTFETCH_DIR="$REAL_HOME/.config/fastfetch"
FASTFETCH_CONFIG="$FASTFETCH_DIR/config.jsonc"
ASCII_FILE="$FASTFETCH_DIR/ascii.txt"

BACKGROUND_FILE="$ASSETS_DIR/background.png"
BOOT_LOGO_FILE="$ASSETS_DIR/logo.png"
WHITE_LOGO_FILE="$ASSETS_DIR/whitelogo.png"

BACKGROUND_URL="https://raw.githubusercontent.com/Duckycel/SakuraBRP/main/background.png"
BOOT_LOGO_URL="https://raw.githubusercontent.com/Duckycel/SakuraBRP/main/logo.png"
WHITE_LOGO_URL="https://raw.githubusercontent.com/Duckycel/SakuraBRP/main/whitelogo.png"

NIXOS_CONFIG="/etc/nixos/configuration.nix"
SAKURA_NIX="/etc/nixos/sakura-fastfetch.nix"

echo "Setting up Sakura OS identification..."

mkdir -p "$IDENT_DIR"
mkdir -p "$ASSETS_DIR"
mkdir -p "$FASTFETCH_DIR"

download_file() {
    local url="$1"
    local out="$2"

    echo "Downloading $(basename "$out")..."
    if command -v curl >/dev/null 2>&1; then
        curl -L "$url" -o "$out"
    elif command -v wget >/dev/null 2>&1; then
        wget -O "$out" "$url"
    else
        echo "Neither curl nor wget is installed."
        echo "Run the installer with nix-shell -p curl"
        exit 1
    fi
}

ensure_fastfetch_permanent() {
    echo "Ensuring fastfetch is installed permanently..."

    if [ ! -f "$NIXOS_CONFIG" ]; then
        echo "Could not find $NIXOS_CONFIG"
        return
    fi

    cat > "$SAKURA_NIX" <<'EOF'
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    fastfetch
  ];
}
EOF

    if ! grep -q 'sakura-fastfetch.nix' "$NIXOS_CONFIG"; then
        if grep -q 'imports = \[' "$NIXOS_CONFIG"; then
            sed -i '/imports = \[/a\    ./sakura-fastfetch.nix' "$NIXOS_CONFIG"
        else
            sed -i '/{[[:space:]]*$/a\
  imports = [\
    ./sakura-fastfetch.nix\
  ];\
' "$NIXOS_CONFIG"
        fi
    fi

    echo "Running nixos-rebuild switch..."
    nixos-rebuild switch
}

write_fastfetch_files() {
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

    chown -R "$REAL_USER":"$(id -gn "$REAL_USER" 2>/dev/null || echo users)" "$FASTFETCH_DIR"
}

write_os_release() {
    echo "Trying to write /etc/os-release..."

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
        echo "/etc/os-release written."
    else
        echo "Could not write /etc/os-release on this NixOS setup, skipping."
    fi
}

apply_wallpaper_if_possible() {
    if command -v feh >/dev/null 2>&1; then
        echo "Applying wallpaper with feh..."
        sudo -u "$REAL_USER" feh --bg-fill "$BACKGROUND_FILE" || true
    else
        echo "feh is not installed, skipping wallpaper apply."
    fi
}

echo "Downloading Sakura assets..."
download_file "$BACKGROUND_URL" "$BACKGROUND_FILE"
download_file "$BOOT_LOGO_URL" "$BOOT_LOGO_FILE"
download_file "$WHITE_LOGO_URL" "$WHITE_LOGO_FILE"

chown -R "$REAL_USER":"$(id -gn "$REAL_USER" 2>/dev/null || echo users)" "$SAKURA_DIR"

ensure_fastfetch_permanent
write_fastfetch_files
write_os_release

echo "Setting hostname..."
hostnamectl set-hostname sakura || true

apply_wallpaper_if_possible

echo
echo "Done."
echo "Fastfetch is installed permanently through NixOS."
echo "Background: $BACKGROUND_FILE"
echo "Boot logo:  $BOOT_LOGO_FILE"
echo "White logo: $WHITE_LOGO_FILE"
echo "Fastfetch config: $FASTFETCH_CONFIG"
