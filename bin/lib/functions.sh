ALPINE_DOWNLOAD_URL_KERNEL=https://dl-cdn.alpinelinux.org/alpine/latest-stable/releases/armv7/alpine-rpi-3.17.0-armv7.tar.gz
ALPINE_DOWNLOAD_URL_ROOTFS=https://dl-cdn.alpinelinux.org/alpine/latest-stable/releases/armv7/alpine-minirootfs-3.17.0-armv7.tar.gz
BUSYBOX_DOWNLOAD_URL=https://www.busybox.net/downloads/binaries/1.31.0-defconfig-multiarch-musl/busybox-armv7l

INITRAMFS_REMOTE_LOCATION=
TEMP=$ROOT/temp
ALPINE_KERNEL=$TEMP/alpine-kernel.tar.gz
ALPINE_ROOTFS=$TEMP/alpine-rootfs.tar.gz
ALPINE_DIR=$TEMP/alpine
BUILD_DIR=$TEMP/build
INITRAMFS_BUILD_DIR=$BUILD_DIR/initramfs
DIST_DIR=$ROOT/dist
ROOTFS_BUILD_DIR=$BUILD_DIR/rootfs

# Root file system size in megabyte
if [ -z "$ROOTFS_SIZE" ];
then
    ROOTFS_SIZE=256
fi

CMD_LINE_OPTION="modules=loop,squashfs,sd-mod,usb-storage overlaytmpfs=yes console=tty1 cgroup_memory=1 cgroup_enable=memory swapaccount=1"

function setup_build_env_initramfs {
    sudo rm -rf "$BUILD_DIR"  "$ALPINE_DIR"
    mkdir -p "$ALPINE_DIR" "$BUILD_DIR" "$INITRAMFS_BUILD_DIR" 

    if [ ! -f "$ALPINE_KERNEL" ];
    then
        echo "Downloading alpine rpi kernel ($ALPINE_DOWNLOAD_URL_KERNEL)"
        curl -L "$ALPINE_DOWNLOAD_URL_KERNEL" -o "$ALPINE_KERNEL"
    fi

    if [ -z "$(ls -A $ALPINE_DIR)" ];
    then
        echo "Extracting alpine kernel (ALPINE_KERNEL)"
        tar -C "$ALPINE_DIR" -xvf "$ALPINE_KERNEL"
    fi
}

function setup_build_env_rootfs {
    echo "Installing requirements to execute ARM excutables"
    sudo apt install qemu-user qemu-user-static gcc-aarch64-linux-gnu binutils-aarch64-linux-gnu binutils-aarch64-linux-gnu-dbg build-essential

    sudo rm -rf "$ROOTFS_BUILD_DIR"
    mkdir -p "$BUILD_DIR" "$ROOTFS_BUILD_DIR"

    if [ ! -f "$ALPINE_ROOTFS" ];
    then
        echo "Downloading alpine root filesystem ($ALPINE_DOWNLOAD_URL_ROOTFS)"
        curl -L "$ALPINE_DOWNLOAD_URL_ROOTFS" -o "$ALPINE_ROOTFS"
    fi

    if [ -z "$(ls -A $ROOTFS_BUILD_DIR)" ];
    then
        echo "Extracting alpine root filesystem (ALPINE_ROOTFS)"
        tar -C "$ROOTFS_BUILD_DIR" -xvf "$ALPINE_ROOTFS"
    fi
}

function build_initramfs {
    setup_build_env_initramfs

    cp "$ALPINE_DIR/boot/initramfs-rpi4" "$INITRAMFS_BUILD_DIR"
    
    echo "Extracting initramfs-rpi4"
    cd $INITRAMFS_BUILD_DIR && zcat initramfs-rpi4 | cpio -idmv && cd -

    echo "Removing stock initramfs-rpi4 ($INITRAMFS_BUILD_DIR/initramfs-rpi4)"
    sudo rm -f "$INITRAMFS_BUILD_DIR/initramfs-rpi4"

    echo "Adding custom init script"
    mv "$INITRAMFS_BUILD_DIR/init" "$INITRAMFS_BUILD_DIR/init2"
    rm -f "$INITRAMFS_BUILD_DIR/init"
    cp "$ROOT/etc/init" "$INITRAMFS_BUILD_DIR/init"
    #cp "$ROOT/etc/init2" "$INITRAMFS_BUILD_DIR/init2"
    chmod +x "$INITRAMFS_BUILD_DIR/init"

    echo "Adding custom busybox binary with tftp support..."
    curl -L "$BUSYBOX_DOWNLOAD_URL" > "$INITRAMFS_BUILD_DIR/bin/busybox" 
    chmod +x "$INITRAMFS_BUILD_DIR/bin/busybox"

    package_initramfs
}

function build_rootfs {
    setup_build_env_rootfs

    echo "Adding custom changes to alpine mini root filesystem..."

    mkdir -p "$ROOTFS_BUILD_DIR/etc/udev/rules.d/"

    cp "$ROOT/etc/rootfs-setup.sh" "$ROOTFS_BUILD_DIR"
    cp "$ROOT/etc/interfaces" "$ROOTFS_BUILD_DIR/etc/network/interfaces"
    cp "$ROOT/etc/ntp" "$ROOTFS_BUILD_DIR/etc/periodic/hourly/"
    
    cp "$ROOT/etc/zram-load.conf" "$ROOTFS_BUILD_DIR/etc/modules-load.d/zram.conf"
    cp "$ROOT/etc/zram-modprobe.conf" "$ROOTFS_BUILD_DIR/etc/modprobe.d/zram.conf"
    cp "$ROOT/etc/zram-rules.conf" "$ROOTFS_BUILD_DIR/etc/udev/rules.d/99-zram.rules"
    cp "$ROOT/etc/zram-init" "$ROOTFS_BUILD_DIR/sbin/zram-init"

    cp "$ROOT/etc/bootstrap-service" "$ROOTFS_BUILD_DIR/etc/init.d/bootstrap"
    cp "$ROOT/etc/bootstrap" "$ROOTFS_BUILD_DIR/bin/bootstrap"
    cp "$ROOT/etc/rcS" "$ROOTFS_BUILD_DIR/etc/init.d/"
    cp "$ROOT/etc/rootfs-init" "$ROOTFS_BUILD_DIR/init"
    cp "$ROOT/etc/cgconfig.conf" "$ROOTFS_BUILD_DIR/etc/cgconfig.conf"

    echo "BOOTSTRAP_LOCATION=$BOOTSTRAP_LOCATION" > "$ROOTFS_BUILD_DIR/etc/bootstrap.conf"

    rootfs_add_modules

    echo "cgroup /sys/fs/cgroup cgroup defaults 0 0" >> "$ROOTFS_BUILD_DIR/etc/fstab"
    echo "ftdi_sio" >> "$ROOTFS_BUILD_DIR/etc/modules"

    #set up nameservers for apk install
    cat /etc/resolv.conf | grep nameserver > "$ROOTFS_BUILD_DIR/etc/resolv.conf"

    #setup inside the chroot
    echo "Setting up the the rootfs using chroot"
    sudo chroot "$ROOTFS_BUILD_DIR" /rootfs-setup.sh "$HOSTNAME" "$PASSWORD" "$SSH_PUB_KEY"

    #cleanup
    rm -f "$ROOTFS_BUILD_DIR/etc/resolv.conf" "$ROOTFS_BUILD_DIR/rootfs-setup.sh"

    create_rootfs_archive
}

function rootfs_add_modules {
    unsquashfs -d "$BUILD_DIR/modules" "$ALPINE_DIR/boot/modloop-rpi4"
    cp -R "$BUILD_DIR/modules/modules" "$ROOTFS_BUILD_DIR/lib/"
}

function read_remote_location_info {
    if [ ! -z "$HTTP_SOURCE" ];
    then
        SOURCE=1
        return
    fi

    if [ ! -z "$TFTP_HOST" ] && [ ! -z "$TFTP_PATH" ]
    then
        SOURCE=2
        return
    fi

    echo "Data source?:"
    echo ""
    echo "1. HTTP"
    echo "2. TFTP"
    echo ""
    echo "Source (2): "
    read SOURCE

    if [ -z "$SOURCE" ];
    then
        SOURCE=2
    fi

    if [ $SOURCE == "1" ];
    then
        while [ -z "$HTTP_SOURCE" ]
        do
            echo "Enter the remote URL for the root filesystem:"
            read HTTP_SOURCE
        done
    fi

    if [ $SOURCE == "2" ];
    then
        while [ -z "$TFTP_HOST" ]
        do
            echo "Enter the TFTP host:"
            read TFTP_HOST
        done

        echo "Enter the TFTP path (rootfs.ext4.tar.gz):"
        read TFTP_PATH
        
        if [ -z "$TFTP_PATH" ];
        then
            TFTP_PATH=rootfs.ext4.tar.gz
        fi
    fi
}

function write_cmdline {
    if [ $SOURCE == "1" ];
    then
        CMD_LINE_OPTION="$CMD_LINE_OPTION ROOTFS_HTTP=$HTTP_SOURCE" >> "$DIST_DIR/cmdline.txt"
    fi

    if [ $SOURCE == "2" ];
    then
        CMD_LINE_OPTION="$CMD_LINE_OPTION ROOTFS_TFTP_HOST=$TFTP_HOST ROOTFS_TFTP_FILE=$TFTP_PATH" >> "$DIST_DIR/cmdline.txt"
    fi
    echo "Using startup command '$CMD_LINE_OPTION'"
    echo "$CMD_LINE_OPTION" > "$DIST_DIR/cmdline.txt"
}

function create_rootfs_archive {
    echo "Creating new rootfs"
    dd if=/dev/zero of="$BUILD_DIR/rootfs.ext4" bs=1M count=$ROOTFS_SIZE
    
    echo "Formatting new rootfs as ext4"
    mkfs.ext4 "$BUILD_DIR/rootfs.ext4"

    sudo losetup -fP "$BUILD_DIR/rootfs.ext4"
    local LOOP_DEVICE=`losetup -a | grep -i "rootfs.ext4" | awk -F ':' '{print $1}'`

    mkdir "$BUILD_DIR/new_rootfs"
    echo sudo mount -t ext4 "$LOOP_DEVICE" "$BUILD_DIR/new_rootfs"
    sudo mount -t ext4 "$LOOP_DEVICE" "$BUILD_DIR/new_rootfs"

    echo "Adding content to new root filesystem"
    sudo chown -R root:root "$ROOTFS_BUILD_DIR"
    sudo rsync -va "$ROOTFS_BUILD_DIR/" "$BUILD_DIR/new_rootfs"

    echo "Unmount and remove temp device"
    sudo umount "$BUILD_DIR/new_rootfs"
    sudo losetup -d "$LOOP_DEVICE"

    echo "Creating new rootfs archive..."
    cd "$BUILD_DIR" && tar -cvf - "rootfs.ext4" | gzip --best > "$BUILD_DIR/rootfs.ext4.tar.gz" && cd -
}

function package_initramfs {
    echo "Creating new initramfs-rpi4 ($BUILD_DIR/initramfs-rpi4)"
    rm -f "$BUILD_DIR/initramfs-rpi4"
    cd "$INITRAMFS_BUILD_DIR" && find . | cpio -ov --format=newc | gzip --best > "$BUILD_DIR/initramfs-rpi4" && cd -
}

function dist {
    sudo rm -rf "$DIST_DIR" 

    echo "Adding base alpine boot files"
    cp -R "$ALPINE_DIR" "$DIST_DIR"
    
    echo "Adding custom initramfs..."
    rm -f "$DIST_DIR/boot/initramfs-rpi4"
    cp "$BUILD_DIR/initramfs-rpi4" "$DIST_DIR/boot/initramfs-rpi4"

    echo "Adding rootfs..."
    cp "$BUILD_DIR/rootfs.ext4.tar.gz" "$DIST_DIR"

    read_remote_location_info
    write_cmdline    
}