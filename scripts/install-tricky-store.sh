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

echo "=== Tricky Store 1.4.1 Waydroid Integration ==="

# 1. Check Waydroid container status
echo "Checking Waydroid container status..."
if ! waydroid status | grep -qE "Container:[[:space:]]+RUNNING"; then
    echo "Waydroid container is not running. Starting/restarting it..."
    sudo systemctl restart waydroid-container.service
    sleep 3
    if ! waydroid status | grep -qE "Container:[[:space:]]+RUNNING"; then
        echo "Container still not running. Trying direct container start..."
        sudo waydroid container start || true
        sleep 3
    fi
    if ! waydroid status | grep -qE "Container:[[:space:]]+RUNNING"; then
        echo "Error: Failed to start Waydroid container."
        echo "Please ensure Waydroid is properly installed and initialized."
        exit 1
    fi
fi

# 2. Retrieve Tricky Store 1.4.1 release info
echo "Fetching Tricky Store v1.4.1 release info from GitHub..."
RELEASE_JSON=$(curl -s https://api.github.com/repos/5ec1cff/TrickyStore/releases/tags/1.4.1)
DOWNLOAD_URL=$(echo "$RELEASE_JSON" | grep "browser_download_url" | cut -d '"' -f 4 | grep -i '.zip' | head -n 1)

if [ -z "$DOWNLOAD_URL" ]; then
    echo "Error: Could not retrieve download URL for Tricky Store v1.4.1."
    echo "Please check your internet connection or GitHub API limits."
    exit 1
fi

echo "Found download URL: $DOWNLOAD_URL"

# 3. Download Tricky Store
TMP_ZIP=$(mktemp -t tricky_store_XXXXXX.zip)
echo "Downloading Tricky Store to temporary location: $TMP_ZIP"
curl -L -o "$TMP_ZIP" "$DOWNLOAD_URL"

if [ ! -f "$TMP_ZIP" ] || [ ! -s "$TMP_ZIP" ]; then
    echo "Error: Failed to download Tricky Store."
    exit 1
fi

# 4. Detect active Waydroid data directory
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

# 5. Push to Waydroid container and install
echo "Preparing container directories..."
sudo mkdir -p "$DATA_DIR/local/tmp"
sudo cp "$TMP_ZIP" "$DATA_DIR/local/tmp/tricky-store.zip"
sudo chmod 644 "$DATA_DIR/local/tmp/tricky-store.zip"

echo "Installing Tricky Store module via Magisk..."
if ! sudo waydroid shell -- magisk --install-module /data/local/tmp/tricky-store.zip; then
    echo "Error: Installation failed. Ensure Magisk is installed, running and fully configured."
    echo "You can install Magisk using: ./scripts/install-magisk.sh"
    rm -f "$TMP_ZIP"
    sudo rm -f "$DATA_DIR/local/tmp/tricky-store.zip"
    exit 1
fi

# 6. Cleanup
echo "Cleaning up temporary files..."
rm -f "$TMP_ZIP"
sudo rm -f "$DATA_DIR/local/tmp/tricky-store.zip"

echo "========================================="
echo "Tricky Store integration completed successfully!"
echo "Please restart your Waydroid container to apply changes:"
echo "  sudo systemctl restart waydroid-container.service"
echo "========================================="
