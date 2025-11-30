#!/bin/sh

set -e

export PROFILENAME="wipi"
export SYSNAME="WiPi OS"
export ROOT_DIR="$(dirname -- "$(readlink -f -- "$0")")"
export CACHE_DIR="$ROOT_DIR/cache"
export SRC_DIR="$ROOT_DIR/src"
export REPO_DIR="$CACHE_DIR/repo"
export APK_DIR="$SRC_DIR/apk"
export APKTEMP_DIR="$CACHE_DIR/apk"
export BUILD_USER="build" # User with abuild setup
export MAX_THREADS="$(nproc)"
export DISTRO_TARGET_ARCH="aarch64"
export REPOS_FILE="$SRC_DIR/repositories"
export PKG_PROFILE="standard"
export BOOT_DIR="$CACHE_DIR/boot"
export FILESYSTEM_DIR="$CACHE_DIR/root"
export FIRMWARE_DIR="$CACHE_DIR/firmware"
export MOUNT_DIR="$CACHE_DIR/mnt"
export IMG_PATH="$CACHE_DIR/$PROFILENAME-os.img"

# Allow overriding the default variables through a
# separate script, which is added to gitignore
if [ -f "$SRC_DIR/config.override.sh" ]; then
	echo "[*] Loaded config overrides"
	. "$SRC_DIR/config.override.sh"
fi

echo "Config:"
echo " - PROFILENAME: $PROFILENAME"
echo " - SYSNAME: $SYSNAME"
echo " - ROOT_DIR: $ROOT_DIR"
echo " - CACHE_DIR: $CACHE_DIR"
echo " - SRC_DIR: $SRC_DIR"
echo " - REPO_DIR: $REPO_DIR"
echo " - APK_DIR: $APK_DIR"
echo " - APKTEMP_DIR: $APKTEMP_DIR"
echo " - BUILD_USER: $BUILD_USER"
echo " - MAX_THREADS: $MAX_THREADS"
echo " - DISTRO_TARGET_ARCH: $DISTRO_TARGET_ARCH"
echo " - REPOS_FILE: $REPOS_FILE"
echo " - PKG_PROFILE: $PKG_PROFILE"
echo " - FILESYSTEM_DIR: $FILESYSTEM_DIR"
echo " - FIRMWARE_DIR: $FIRMWARE_DIR"
echo " - IMG_DIR: $IMG_DIR"
echo " - IMG_PATH: $IMG_PATH"
echo " - IMG_VOLID: $IMG_VOLID"

mkdir -p "$CACHE_DIR"
chmod 777 "$CACHE_DIR" # Allow read-write for build user
