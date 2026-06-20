#!/usr/bin/env bash
set -euo pipefail

# Find the directory of the script and repo root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

# Ensure we run as a regular user with sudo access
if [ "$EUID" -eq 0 ]; then
  echo "Please run this script as a normal user (without sudo):"
  echo "  $0"
  exit 1
fi

echo "=== Tricky Store Configuration ==="

# Detect active Waydroid data directory
echo "Detecting active Waydroid data directory..."
DATA_DIR="/var/lib/waydroid/data"
if [ -d "$HOME/.local/share/waydroid/data" ]; then
    DATA_DIR="$HOME/.local/share/waydroid/data"
elif [ -f "/var/lib/waydroid/lxc/waydroid/config_session" ]; then
    PARSED_DIR=$(grep -E 'lxc\.mount\.entry[[:space:]]*=[[:space:]]*[^[:space:]]+[[:space:]]+data[[:space:]]' "/var/lib/waydroid/lxc/waydroid/config_session" | awk '{print $3}' || true)
    if [ -n "$PARSED_DIR" ] && [ -d "$PARSED_DIR" ]; then
        DATA_DIR="$PARSED_DIR"
    fi
fi
echo "Using Waydroid data directory on host: $DATA_DIR"

TRICKY_DIR="$DATA_DIR/adb/tricky_store"

echo "Creating Tricky Store directory at: $TRICKY_DIR"
sudo mkdir -p "$TRICKY_DIR"
sudo chmod 700 "$TRICKY_DIR"

# Create target.txt with package names
echo "Creating target.txt..."
sudo tee "$TRICKY_DIR/target.txt" > /dev/null <<EOF
com.google.android.gms
com.whatsapp
EOF
sudo chmod 600 "$TRICKY_DIR/target.txt"

echo "Tricky Store environment initialized!"
echo ""
echo "CRITICAL STEP:"
echo "You must now place your 'keybox.xml' file in the following path on your host (Linux):"
echo "  $TRICKY_DIR/keybox.xml"
echo ""
echo "After copying the file, make sure it has the correct root permissions by running:"
echo "  sudo chown -R root:root $TRICKY_DIR"
echo "  sudo chmod 600 $TRICKY_DIR/keybox.xml"
echo ""
echo "Once the keybox is in place, restart your Waydroid container:"
echo "  sudo systemctl restart waydroid-container.service"
echo "========================================="
