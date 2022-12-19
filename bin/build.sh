#!/bin/bash
ROOT="$(realpath $(cd "$(dirname $(realpath "${BASH_SOURCE[0]}"))" >/dev/null 2>&1 && pwd)/../)"

. $ROOT/bin/lib/functions.sh 

info "Starting initramfs build"
initramfs_build

info "Starting root filesystem build"
rootfs_build

info "Packaging..."
dist

echo ""
echo ""
echo ""

info "Raspberry PI 4 netboot files written to '$DIST_DIR'"
echo ""

info "Updated initramfs is: "
info "$DIST_DIR/boot/initramfs-rpi4"
echo ""
info "Root filesystem is:"
info "$DIST_DIR/rootfs.ext4.tar.gz"

echo ""

info "Copy the '$DIST_DIR' files to the tftp server"