#!/bin/sh

set -e

if [ "$(id -u)" != "0" ]; then
	echo "[!] Run as root"
	exit 1
fi

echo "[*] WiPi OS Builder"

echo "[*] Running config..."
. ./src/config.sh

echo "[*] Setting up cache directory..."
mkdir -p "$CACHE_DIR"
chmod 777 "$CACHE_DIR" # Allow read-write for build user
# if [ ! -d "$CACHE_DIR/apkcache" ]; then
# 	echo "[*] Setting up APK cache..."
# 	mkdir -p "$CACHE_DIR/apkcache" # Allow caching of alpine packages
# 	apk update
# fi

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
