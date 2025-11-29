#!/bin/sh

set -e

if [ "$(id -u)" != "0" ]; then
	echo "[!] Run as root"
	exit 1
fi

echo "[*] WiPi OS Builder"

echo "[*] Running config..."
. ./src/config.sh

# Setup APKs and build local repository
echo "[*] Setting up APKs..."
doas -u "$BUILD_USER" -- ./src/setup_apks.sh

echo "[*] Building local repository..."
doas -u "$BUILD_USER" -- ./src/build_repo.sh

# Make filesystem
echo "[*] Making filesystem..."
./src/make_filesystem.sh

# Build ISO
echo "[*] Making disk image..."
./src/make_image.sh

echo "[*] Build finished successfully"
