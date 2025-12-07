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
export LOG_FILE="$CACHE_DIR/build.log"
export BUILD_USER="build" # User with abuild setup
export MAX_THREADS="$(nproc)"
export DISTRO_TARGET_ARCH="aarch64"
export REPOS_FILE="$SRC_DIR/repositories"
export PKG_PROFILE="standard"
export BOOT_DIR="$CACHE_DIR/boot"
export FILESYSTEM_DIR="$CACHE_DIR/root"
export MOUNT_DIR="$CACHE_DIR/mnt"
export BOOT_LABEL="$PROFILENAME-boot" # Up to 11 chars long!
export ROOT_LABEL="$PROFILENAME-root"
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
echo " - LOG_FILE: $LOG_FILE"
echo " - BUILD_USER: $BUILD_USER"
echo " - MAX_THREADS: $MAX_THREADS"
echo " - DISTRO_TARGET_ARCH: $DISTRO_TARGET_ARCH"
echo " - REPOS_FILE: $REPOS_FILE"
echo " - PKG_PROFILE: $PKG_PROFILE"
echo " - FILESYSTEM_DIR: $FILESYSTEM_DIR"
echo " - MOUNT_DIR: $MOUNT_DIR"
echo " - BOOT_LABEL: $BOOT_LABEL"
echo " - ROOT_LABEL: $ROOT_LABEL"
echo " - IMG_PATH: $IMG_PATH"
