#!/bin/sh

# initrdbo
if [ ! -d "$APKTEMP_DIR/initrdbo" ]; then
	mkdir -p "$APKTEMP_DIR/initrdbo"
	cp -r "$APK_DIR/initrdbo/." "$APKTEMP_DIR/initrdbo/."
	cd "$APKTEMP_DIR/initrdbo"
	abuild checksum
fi

# rpi-boot
if [ ! -d "$APKTEMP_DIR/rpi-boot" ]; then
	mkdir -p "$APKTEMP_DIR/rpi-boot"
	cp -r "$APK_DIR/rpi-boot/." "$APKTEMP_DIR/rpi-boot/."
	cd "$APKTEMP_DIR/rpi-boot"
	abuild checksum
fi

# wipi-conf
if [ ! -d "$APKTEMP_DIR/wipi-conf" ]; then
	mkdir -p "$APKTEMP_DIR/wipi-conf/"
	cp "$APK_DIR/wipi-conf/APKBUILD" "$APKTEMP_DIR/wipi-conf/"
	cd "$APK_DIR/wipi-conf"
	tar -czf "$APKTEMP_DIR/wipi-conf/rootfs.tar.gz" rootfs
	cd "$APKTEMP_DIR/wipi-conf"
	abuild checksum
fi
