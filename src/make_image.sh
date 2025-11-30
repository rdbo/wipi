#!/bin/sh

set -e

# Avoid issues in case a previous 'make_image' run failed
mkdir -p "$MOUNT_DIR"
umount "$MOUNT_DIR" > /dev/null 2>&1 || true

# Calculate sizes for the disk image
echo "[*] Calculating partition sizes..."
boot_size_mb=512
boot_size="$((boot_size_mb * 1024 * 1024))"
boot_size_min="$(du -sb "$BOOT_DIR" | cut -f1)"
echo "Minimum boot size: $(numfmt --to=iec --suffix=B "$boot_size_min")"
echo "Boot size: $(numfmt --to=iec --suffix=B "$boot_size")"
if [ $boot_size -lt $boot_size_min ]; then
	echo "[!] Boot size too small! Make adjustments in 'make_image.sh'"
	exit 1
fi

root_size_min="$(du -sb "$FILESYSTEM_DIR" | cut -f1)"
root_size_mb=512
root_size="$((root_size_mb * 1024 * 1024))"
echo "Minimum root size: $(numfmt --to=iec --suffix=B "$root_size_min")"
echo "Root size: $(numfmt --to=iec --suffix=B "$root_size")"
if [ $root_size -lt $root_size_min ]; then
	echo "[!] Root size too small! Make adjustments in 'make_image.sh'"
	exit 1
fi

disk_size_mb=$((boot_size_mb + root_size_mb + 16)) # Extra 16MB for partition things
disk_size=$((disk_size_mb * 1024 * 1024))
echo "Disk size: $(numfmt --to=iec --suffix=B "$disk_size")"

# Create disk image file
echo "[*] Creating disk..."
dd if=/dev/zero of="$IMG_PATH" count="$disk_size_mb" bs=1M

# Setup disk partitions
echo "[*] Setting up partitions..."
disk_dev="$(losetup --show -fP "$IMG_PATH")"
echo "Disk device: $disk_dev"
echo "label: mbr" | sfdisk -f "$disk_dev"
echo ", ${boot_size_mb}M, w95_fat32_lba" | sfdisk -f "$disk_dev" # boot
echo ", , linux" | sfdisk -a -f "$disk_dev" # root
sync
boot_part="${disk_dev}p1"
root_part="${disk_dev}p2"

boot_label="$PROFILENAME-boot" # NOTE: up to 11 chars long!
mkfs.fat -F32 -n "$boot_label" "$boot_part"

root_label="$PROFILENAME-root"
mkfs.ext4 -L "$root_label" "$root_part"

# Setup boot partition
mount "$boot_part" "$MOUNT_DIR"
cp -r "$BOOT_DIR/." "$MOUNT_DIR/."
printf "console=serial0,115200 console=tty1 root=LABEL="$root_label" rootfstype=ext4 fsck.repair=yes rootwait resize" > "$MOUNT_DIR/cmdline.txt"
cp "$SRC_DIR/config.txt" "$MOUNT_DIR/"
umount "$MOUNT_DIR"

# Setup root partition
mount "$root_part" "$MOUNT_DIR"
cp -a "$FILESYSTEM_DIR/." "$MOUNT_DIR/."
umount "$MOUNT_DIR"

# Detach loop device
echo "[*] Detaching loop device..."
losetup -d "$disk_dev"
