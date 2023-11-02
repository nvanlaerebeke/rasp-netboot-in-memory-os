#!/bin/bash
ROOT="$(realpath $(cd "$(dirname $(realpath "${BASH_SOURCE[0]}"))" >/dev/null 2>&1 && pwd)/../)"

. $ROOT/bin/lib/functions.sh 

info "Installing basic requirements"
requirements

info "Starting initramfs build"
initramfs_build

info "Starting root filesystem build"
rootfs_build

info "Packaging..."
dist

echo ""
echo ""
echo ""

info "Raspberry PI 4 netboot files written to 'dist'"
echo ""

info "Updated initramfs is: "
info "dist/boot/initramfs-rpi4"
echo ""
info "Root filesystem is:"
info "dist/rootfs.ext4.tar.gz"

echo ""

info "Copy the 'dist' files to the tftp server"