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

echo "=== Zygisk Next Waydroid Integration ==="

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

# 2. Patch seccomp configuration
SECCOMP_FILE="/var/lib/waydroid/lxc/waydroid/waydroid.seccomp"
if [ -f "$SECCOMP_FILE" ]; then
    if grep -q "reboot" "$SECCOMP_FILE"; then
        echo "Found 'reboot' restriction in seccomp profile. Removing it to allow Zygisk Next injection..."
        sudo cp "$SECCOMP_FILE" "${SECCOMP_FILE}.bak"
        sudo sed -i '/reboot/d' "$SECCOMP_FILE"
        echo "Seccomp patched successfully. Restarting waydroid-container to apply changes..."
        sudo systemctl restart waydroid-container.service
        sleep 3
        # Ensure it's running again
        if ! waydroid status | grep -qE "Container:[[:space:]]+RUNNING"; then
            echo "Waiting for Waydroid container to start..."
            sleep 3
        fi
    else
        echo "The 'reboot' restriction is already removed from seccomp profile."
    fi
else
    echo "Warning: $SECCOMP_FILE not found. Skipping seccomp patch."
fi

# 3. Retrieve latest Zygisk Next release info
echo "Fetching latest Zygisk Next release from GitHub..."
RELEASE_JSON=$(curl -s https://api.github.com/repos/Dr-TSNG/ZygiskNext/releases/latest)
DOWNLOAD_URL=$(echo "$RELEASE_JSON" | grep "browser_download_url" | cut -d '"' -f 4 | grep -i 'release.zip' | head -n 1)

if [ -z "$DOWNLOAD_URL" ]; then
    echo "Error: Could not retrieve download URL for Zygisk Next."
    echo "Please check your internet connection or GitHub API limits."
    exit 1
fi

VERSION=$(echo "$RELEASE_JSON" | grep '"tag_name":' | cut -d '"' -f 4)
echo "Found Zygisk Next version: $VERSION"

# 4. Download Zygisk Next
TMP_ZIP=$(mktemp -t zygisk_next_XXXXXX.zip)
echo "Downloading Zygisk Next to temporary location: $TMP_ZIP"
curl -L -o "$TMP_ZIP" "$DOWNLOAD_URL"

if [ ! -f "$TMP_ZIP" ] || [ ! -s "$TMP_ZIP" ]; then
    echo "Error: Failed to download Zygisk Next."
    exit 1
fi

# 5. Push to Waydroid container and install
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

echo "Preparing container directories..."
sudo mkdir -p "$DATA_DIR/local/tmp"
sudo cp "$TMP_ZIP" "$DATA_DIR/local/tmp/zygisk-next.zip"
sudo chmod 644 "$DATA_DIR/local/tmp/zygisk-next.zip"

echo "Installing Zygisk Next module via Magisk..."
if ! sudo waydroid shell -- magisk --install-module /data/local/tmp/zygisk-next.zip; then
    echo "Error: Installation failed. Ensure Magisk is installed and running first."
    echo "You can install Magisk using: ./scripts/install-magisk.sh"
    rm -f "$TMP_ZIP"
    sudo rm -f "$DATA_DIR/local/tmp/zygisk-next.zip"
    exit 1
fi

# 6. Cleanup
echo "Cleaning up temporary files..."
rm -f "$TMP_ZIP"
sudo rm -f "$DATA_DIR/local/tmp/zygisk-next.zip"

echo "========================================="
echo "Zygisk Next integration completed successfully!"
echo "Please restart your Waydroid container to apply changes:"
echo "  sudo systemctl restart waydroid-container.service"
echo ""
echo "CRITICAL: Open the Magisk app inside Waydroid and ensure that"
echo "'Zygisk' is DISABLED in the settings. Zygisk Next runs independently"
echo "and will fail if the native Magisk Zygisk is also enabled."
echo "========================================="
