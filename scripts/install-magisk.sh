#!/usr/bin/env bash
set -euo pipefail

# Find the directory of the script and repo root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

echo "Building WaydroidSU (wsu) using Nix..."
# Build as the current user to avoid Nix environment/permissions issues when running as root
WSU_PATH=$(nix build "$REPO_DIR#waydroidsu" --no-link --print-out-paths)

echo "WaydroidSU built successfully at: $WSU_PATH"

echo "Running WaydroidSU installation..."
# wsu install requires root/sudo, so we execute the store binary under sudo
sudo "$WSU_PATH/bin/wsu" install "$@"

echo "WaydroidSU/Magisk installation completed successfully!"
echo "Please restart your Waydroid container to apply changes:"
echo "  sudo systemctl restart waydroid-container.service"

