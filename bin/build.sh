#!/bin/bash
set -e

ROOT="$(realpath $(cd "$(dirname $(realpath "${BASH_SOURCE[0]}"))" >/dev/null 2>&1 && pwd)/../)"

. $ROOT/bin/lib/functions.sh 

info "Installing basic requirements"
requirements

info "Building cache"
build_cache

info "Starting initramfs build"
initramfs_build

info "Starting root filesystem build"
rootfs_build

info "Packaging..."
dist

echo ""

info "Raspberry PI 4 netboot files written to '$DIST_DIR"
echo ""

info "Updated initramfs is: "
info "$DIST_DIR/boot/initramfs-rpi"
echo ""
info "Root filesystem is:"
info "$DIST_DIR/rootfs.ext4.tar.gz"

echo ""

info "Copy the contents of '$DIST_DIR' to the tftp server"