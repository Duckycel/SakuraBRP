#!/usr/bin/env bash
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "Please run this script with sudo."
  exit 1
fi

CONFIG="/etc/nixos/configuration.nix"
SAKURA_DIR="/etc/nixos/sakura"
SYSTEM_NIX="$SAKURA_DIR/system.nix"
BACKUP="/etc/nixos/configuration.nix.bak.$(date +%s)"

mkdir -p "$SAKURA_DIR"

echo "Backing up configuration.nix to $BACKUP"
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

echo "Fixing configuration.nix imports..."
python3 - <<'PY'
from pathlib import Path
import re
import sys

config_path = Path("/etc/nixos/configuration.nix")
text = config_path.read_text()

target = "./sakura/system.nix"

# Find all imports blocks
pattern = re.compile(r'(^[ \t]*imports\s*=\s*\[.*?^\s*\];)', re.MULTILINE | re.DOTALL)
matches = list(pattern.finditer(text))

if not matches:
    print("No imports block found in configuration.nix")
    print("Please add this manually inside the main config:")
    print("  imports = [ ./sakura/system.nix ];")
    sys.exit(1)

# Keep the first imports block, remove later duplicate imports blocks that only existed from earlier broken script runs
first = matches[0]
first_block = first.group(0)

# Ensure target import is inside first block
if target not in first_block:
    # Put it before closing ];
    first_block = re.sub(r'(^\s*\];)', f'    {target}\n\\1', first_block, flags=re.MULTILINE)

new_text = text[:first.start()] + first_block + text[first.end():]

# Remove all later imports blocks entirely
later_matches = list(pattern.finditer(new_text))
if len(later_matches) > 1:
    pieces = []
    last_end = 0
    for i, m in enumerate(later_matches):
        if i == 0:
            continue
        pieces.append(new_text[last_end:m.start()])
        last_end = m.end()
    pieces.append(new_text[last_end:])
    # rebuild with first block retained
    first_match = later_matches[0]
    body = ''.join(pieces)
    # easier: regenerate from scratch
    text2 = new_text
    later_matches2 = list(pattern.finditer(text2))
    for m in reversed(later_matches2[1:]):
        text2 = text2[:m.start()] + text2[m.end():]
    new_text = text2

# Make sure target still exists once
final_matches = list(pattern.finditer(new_text))
fb = final_matches[0].group(0)
if fb.count(target) == 0:
    fb = re.sub(r'(^\s*\];)', f'    {target}\n\\1', fb, flags=re.MULTILINE)
elif fb.count(target) > 1:
    lines = fb.splitlines()
    seen = 0
    cleaned = []
    for line in lines:
        if target in line:
            seen += 1
            if seen > 1:
                continue
        cleaned.append(line)
    fb = "\n".join(cleaned)

new_text = new_text[:final_matches[0].start()] + fb + new_text[final_matches[0].end():]

config_path.write_text(new_text)
PY

echo "Rebuilding NixOS..."
nixos-rebuild switch

echo
echo "Done."
echo "Sakura module: $SYSTEM_NIX"
echo "Backup: $BACKUP"
