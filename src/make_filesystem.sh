#!/bin/sh

set -e

mkdir -p "$FILESYSTEM_DIR"

# Mount filesystems because some packages write to them
# (e.g /dev/null)
umount -R "$FILESYSTEM_DIR/dev" > /dev/null 2>&1 || true
rm -rf "$FILESYSTEM_DIR/dev" > /dev/null 2>&1 || true
mkdir -p "$FILESYSTEM_DIR/dev"
mount --rbind /dev "$FILESYSTEM_DIR/dev"

umount -R "$FILESYSTEM_DIR/proc" > /dev/null 2>&1 || true
rm -rf "$FILESYSTEM_DIR/proc" > /dev/null 2>&1 || true
mkdir -p "$FILESYSTEM_DIR/proc"
mount --rbind /proc "$FILESYSTEM_DIR/proc"

# Mount temporary boot dir, which will be populated by the
# kernel and initramfs packages
umount -R "$FILESYSTEM_DIR/boot" > /dev/null 2>&1 || true
rm -rf "$FILESYSTEM_DIR/boot" > /dev/null 2>&1 || true
mkdir -p "$BOOT_DIR" "$FILESYSTEM_DIR/boot"
mount --rbind "$BOOT_DIR" "$FILESYSTEM_DIR/boot"

pkgs="$(cat "$SRC_DIR/pkglist.$PKG_PROFILE" | sed 's/#.*//g' | tr '\n' ' ')"
echo "Packages: $pkgs"

# Overwrite initrdbo module config
mkdir -p "$FILESYSTEM_DIR/etc/initrdbo.d"
cp "$SRC_DIR/initramfs_modules" "$FILESYSTEM_DIR/etc/initrdbo.d/base.modules"

# Skip installing APKs if APK database is already set up
if [ ! -d "$FILESYSTEM_DIR/etc/apk" ]; then
	# Initialize APK database
	apk add --arch "$DISTRO_TARGET_ARCH" --initdb -p "$FILESYSTEM_DIR"

	# Install packages
	apk add \
		-p "$FILESYSTEM_DIR" \
		--arch "$DISTRO_TARGET_ARCH" \
		--allow-untrusted \
		--no-cache \
		--repositories-file="$REPOS_FILE" \
		-X "$REPO_DIR/apk" \
		$pkgs
else
	echo "[*] Skipped installing APKs in Filesystem, '/etc/apk' exists"
fi

# Add repositories file to filesystem
mkdir -p "$FILESYSTEM_DIR/etc/apk"
cp "$REPOS_FILE" "$FILESYSTEM_DIR/etc/apk/repositories"

# Overwrite package owned files
cat <<- EOF > "$FILESYSTEM_DIR/etc/issue"
Welcome to WiPi OS (made by rdbo)
Kernel \r on an \m (\l)
EOF

cat <<- EOF > "$FILESYSTEM_DIR/etc/motd"
Welcome to WiPi OS!

For more information about the distribution, see:
 - https://github.com/rdbo/wipi
 - https://wiki.alpinelinux.org

EOF

echo "$PROFILENAME" > "$FILESYSTEM_DIR/etc/hostname"

> "$FILESYSTEM_DIR/etc/fstab"

# Add default network interfaces configuration
mkdir -p "$FILESYSTEM_DIR/etc/network"
cat <<- EOF > "$FILESYSTEM_DIR/etc/network/interfaces"
auto lo
iface lo inet loopback

auto eth0
iface eth0
    use dhcp
EOF

# Create default doas config
cat <<- EOF > "$FILESYSTEM_DIR/etc/doas.conf"
permit persist :wheel
permit nopass root
EOF

# Modify zram-init config
cat <<- EOF > "$FILESYSTEM_DIR/etc/conf.d/zram-init"
load_on_start="yes"
unload_on_stop="yes"
num_devices="1"

type0="swap"
flag0=
size0=\`LC_ALL=C free -m | awk '/^Mem:/{print int(\$2/2)}'\` # 50% of memory reserved for zram
maxs0=1
algo0=zstd
labl0=zram_swap
EOF

# Create common user directories in /etc/skel
dirs="Downloads Documents Pictures Videos Music"
for dir in $dirs; do
	mkdir -p "$FILESYSTEM_DIR/etc/skel/$dir"
done

# Copy /etc/skel to /root (allows for logging in to the desktop environment as root on live boot)
cp -r "$FILESYSTEM_DIR/etc/skel/." "$FILESYSTEM_DIR/root/."

# Enable OpenRC services
rc_add() {
	# $1: service name
	# $2: run level
	chroot "$FILESYSTEM_DIR" rc-update add "$1" "$2"
}

rc_add devfs sysinit
rc_add dmesg sysinit
rc_add mdev sysinit
rc_add hwdrivers sysinit

rc_add hwclock boot
rc_add modules boot
rc_add sysctl boot
rc_add bootmisc boot
rc_add syslog boot

# NOTE: The 'udev' services are used for setting up /dev and doing things
#       such as changing the ownership of certain devices (e.g /dev/dri/cardN).
#       That behavior allows us to access devices (such as the GPU and the input
#       devices) without root access.
rc_add udev sysinit
rc_add udev-trigger sysinit
rc_add udev-settle sysinit
rc_add udev-postmount default
rc_add hostname boot
# rc_add zram-init boot # zram disabled by default. The OS is not supposed to need it.
rc_add networking default # Sets up interfaces based on /etc/network/interfaces
rc_add earlyoom default
rc_add iwd default
rc_add dbus default
rc_add seatd default
# rc_add bluetooth default

rc_add local default # used for start scripts
rc_add sshd default # Access device remotely (headless)

# Setup regular user
if [ ! -e "$FILESYSTEM_DIR/home/user" ]; then
	useradd -R "$FILESYSTEM_DIR" -s /bin/bash -m -G wheel,audio,input,video,seat user
fi
# passwd -R "$FILESYSTEM_DIR" -d user
chroot "$FILESYSTEM_DIR" sh -c 'printf "user:pass" | chpasswd'
chroot "$FILESYSTEM_DIR" sh -c 'printf "root:toor" | chpasswd'

# Merge user patches (https://alpinelinux.org/posts/2025-10-01-usr-merge.html)
# NOTE: Only run this if there are binaries in /bin and /sbin directly.
#       Requires the 'merge-usr' package.
# chroot "$FILESYSTEM_DIR" merge-usr

# Unmount filesystems
umount -R "$FILESYSTEM_DIR/proc"
rm -rf "$FILESYSTEM_DIR/proc"

umount -R "$FILESYSTEM_DIR/dev"
rm -rf "$FILESYSTEM_DIR/dev"

umount -R "$FILESYSTEM_DIR/boot"
rm -rf "$FILESYSTEM_DIR/boot"

# Cleanup firmware files that are not used by any module
# (they can be reinstalled through the `linux-firmware` pkg)
if [ -e "$FIRMWARE_DIR" ]; then
	echo "[*] Skipped firmware cleanup, '$FIRMWARE_DIR' exists"
else
	echo "[*] Cleaning up unused firmware in the filesystem..."
	mv "$FILESYSTEM_DIR/lib/firmware" "$FIRMWARE_DIR"
	mkdir -p "$FILESYSTEM_DIR/lib/firmware"
	# TODO: Make sure that `modinfo` cannot fail. It mail fail due to
	#       the host kernel not being the same as the installer kernel
	find "$FILESYSTEM_DIR"/lib/modules -type f -name "*.ko*" | xargs modinfo -F firmware | sort -u | while read fw; do
		for fname in "$fw" "$fw.zst" "$fw.xz"; do
			if [ -e "${FIRMWARE_DIR}/$fname" ]; then
				install -pD "${FIRMWARE_DIR}/$fname" "$FILESYSTEM_DIR/lib/firmware/$fname"
				break
			fi
		done
	done
fi

