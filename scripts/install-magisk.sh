#!/usr/bin/env bash
set -euo pipefail

# Ensure we run as root/sudo
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root/sudo:"
  echo "  sudo $0"
  exit 1
fi

TEMP_DIR=$(mktemp -d -t waydroid_script-XXXXXX)
echo "Using temporary directory: $TEMP_DIR"

cleanup() {
  echo "Cleaning up..."
  rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

echo "Cloning waydroid_script..."
nix-shell -p git --run "git clone https://github.com/casualsnek/waydroid_script.git $TEMP_DIR"

cd "$TEMP_DIR"

echo "Setting up Python virtual environment and installing Magisk..."
# Run the installation inside a nix-shell containing the required system dependencies (lzip, python, git, sqlite)
nix-shell -p python3 python3Packages.pip lzip git sqlite --run "
  python3 -m venv venv
  source venv/bin/activate
  pip install -r requirements.txt
  python3 main.py install magisk
"

echo "Magisk installation completed successfully!"
