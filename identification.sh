#!/usr/bin/env bash
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "Run with sudo."
  exit 1
fi

REAL_USER="${SUDO_USER:-$(logname 2>/dev/null || echo root)}"
REAL_HOME="$(getent passwd "$REAL_USER" | cut -d: -f6)"
if [ -z "${REAL_HOME:-}" ]; then
  REAL_HOME="/home/$REAL_USER"
fi

NIXOS_DIR="/etc/nixos"
SAKURA_DIR="$NIXOS_DIR/sakura"
SYSTEM_NIX="$SAKURA_DIR/system.nix"
HOME_NIX="$SAKURA_DIR/home.nix"
CONFIG_NIX="$NIXOS_DIR/configuration.nix"

mkdir -p "$SAKURA_DIR"

echo "Prefetching Sakura assets..."
BACKGROUND_HASH="$(nix-prefetch-url https://raw.githubusercontent.com/Duckycel/SakuraBRP/main/background.png)"
LOGO_HASH="$(nix-prefetch-url https://raw.githubusercontent.com/Duckycel/SakuraBRP/main/logo.png)"
WHITELOGO_HASH="$(nix-prefetch-url https://raw.githubusercontent.com/Duckycel/SakuraBRP/main/whitelogo.png)"

echo "Writing $SYSTEM_NIX ..."
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

echo "Writing $HOME_NIX ..."
cat > "$HOME_NIX" <<EOF
{ config, pkgs, lib, ... }:

{
  home.file."Sakura/MandatoryPackages/Identification/Assets/background.png".source = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/Duckycel/SakuraBRP/main/background.png";
    sha256 = "$BACKGROUND_HASH";
  };

  home.file."Sakura/MandatoryPackages/Identification/Assets/logo.png".source = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/Duckycel/SakuraBRP/main/logo.png";
    sha256 = "$LOGO_HASH";
  };

  home.file."Sakura/MandatoryPackages/Identification/Assets/whitelogo.png".source = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/Duckycel/SakuraBRP/main/whitelogo.png";
    sha256 = "$WHITELOGO_HASH";
  };

  home.file.".config/fastfetch/ascii.txt".text = ''
                                           
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
  '';

  home.file.".config/fastfetch/config.jsonc".text = ''
    {
      "logo": {
        "type": "file",
        "source": "\${config.home.homeDirectory}/.config/fastfetch/ascii.txt"
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
  '';

  xsession.initExtra = ''
    \${pkgs.feh}/bin/feh --bg-fill \${config.home.homeDirectory}/Sakura/MandatoryPackages/Identification/Assets/background.png &
  '';
}
EOF

if ! grep -q './sakura/system.nix' "$CONFIG_NIX"; then
  echo "Adding Sakura system import..."
  sed -i '/imports = \[/a\    ./sakura/system.nix' "$CONFIG_NIX"
fi

echo "Rebuilding NixOS..."
nixos-rebuild switch

if command -v home-manager >/dev/null 2>&1; then
  HM_CONFIG_DIR="$REAL_HOME/.config/home-manager"
  mkdir -p "$HM_CONFIG_DIR"

  if [ ! -f "$HM_CONFIG_DIR/home.nix" ]; then
    cat > "$HM_CONFIG_DIR/home.nix" <<EOF
{ config, pkgs, lib, ... }:
{
  imports = [ /etc/nixos/sakura/home.nix ];
  home.username = "$REAL_USER";
  home.homeDirectory = "$REAL_HOME";
  home.stateVersion = "25.11";
}
EOF
    chown -R "$REAL_USER":"$(id -gn "$REAL_USER" 2>/dev/null || echo users)" "$HM_CONFIG_DIR"
  fi

  echo "Applying Home Manager..."
  sudo -u "$REAL_USER" home-manager switch
else
  echo "Home Manager is not installed."
  echo "System module applied."
  echo "User module written to: $HOME_NIX"
  echo "Import it later through Home Manager."
fi

echo "Done."
