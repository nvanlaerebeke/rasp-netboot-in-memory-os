#
# Alpine kernel download URL
#
ALPINE_DOWNLOAD_URL_KERNEL=https://dl-cdn.alpinelinux.org/alpine/v3.17/releases/armv7/alpine-rpi-3.17.0-armv7.tar.gz

#
# Alpine mini root filesystem download URL
# 
# Note: Make sure this is of the same version as the kernel release
#
ALPINE_DOWNLOAD_URL_ROOTFS=https://dl-cdn.alpinelinux.org/alpine/v3.17/releases/armv7/alpine-minirootfs-3.17.0-armv7.tar.gz

#
# Busybox download URL of a version that supports tftp 
#
BUSYBOX_DOWNLOAD_URL=https://www.busybox.net/downloads/binaries/1.31.0-defconfig-multiarch-musl/busybox-armv7l

#
# Temp location where to put the temporary files
#
TEMP=$ROOT/temp

#
# Location to download the alpine kernel to
#
ALPINE_KERNEL=$TEMP/alpine-kernel.tar.gz

#
# Location to download the alpine mini root filesystem to
#
ALPINE_ROOTFS=$TEMP/alpine-rootfs.tar.gz

#
# Location to extract the rpi alpine version to
#
ALPINE_DIR=$TEMP/alpine

#
# Location where the builds will be done
#
BUILD_DIR=$TEMP/build

#
# Location where the new initramfs will be build
#
INITRAMFS_BUILD_DIR=$BUILD_DIR/initramfs

#
# Location where the new root filesystem will be build
#
ROOTFS_BUILD_DIR=$BUILD_DIR/rootfs

#
# Output directory
#
DIST_DIR=$ROOT/dist

#
# Raspberry pi command line (cmdline.txt) command
#
# overlaytmpfs=yes : required to have the root readwrite fully in memory
# console=tty1 : console to use
#
# The following are required for container.io (docker, kubernetes, ...)
# Relates to cgroup support
#
#   cgroup_memory=1
#   cgroup_enable=memory
#   swapaccount=1
#
CMD_LINE_OPTION="modules=loop,squashfs,sd-mod,usb-storage overlaytmpfs=yes console=tty1 cgroup_memory=1 cgroup_enable=memory swapaccount=1"

#
# Root filesystem size in megabyte
#
ROOTFS_SIZE=256

#
# Include the env file, any of the above settings can be overwritten
#
if [ -f "$ROOT/env" ];
then
    . $ROOT/env
fi
