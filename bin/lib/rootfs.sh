
function rootfs_build {
    rootfs_setup_env

    info "Adding custom changes to alpine mini root filesystem..."

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
    info "Setting up the the rootfs using chroot"
    sudo chroot "$ROOTFS_BUILD_DIR" /rootfs-setup.sh "$HOSTNAME" "$PASSWORD" "$SSH_PUB_KEY"

    #cleanup
    rm -f "$ROOTFS_BUILD_DIR/etc/resolv.conf" "$ROOTFS_BUILD_DIR/rootfs-setup.sh"

    rootfs_package
}

function rootfs_setup_env {
    install_qemu_dependencies

    sudo rm -rf "$ROOTFS_BUILD_DIR"
    mkdir -p "$BUILD_DIR" "$ROOTFS_BUILD_DIR"

    if [ ! -f "$ALPINE_ROOTFS" ];
    then
        info "Downloading alpine root filesystem ($ALPINE_DOWNLOAD_URL_ROOTFS)"
        curl -L "$ALPINE_DOWNLOAD_URL_ROOTFS" -o "$ALPINE_ROOTFS"
    fi

    if [ -z "$(ls -A $ROOTFS_BUILD_DIR)" ];
    then
        info "Extracting alpine root filesystem (ALPINE_ROOTFS)"
        tar -C "$ROOTFS_BUILD_DIR" -xvf "$ALPINE_ROOTFS"
    fi
}

function rootfs_add_modules {
    unsquashfs -d "$BUILD_DIR/modules" "$ALPINE_DIR/boot/modloop-rpi4"
    cp -R "$BUILD_DIR/modules/modules" "$ROOTFS_BUILD_DIR/lib/"
}

function rootfs_package {
    info "Creating new rootfs"
    dd if=/dev/zero of="$BUILD_DIR/rootfs.ext4" bs=1M count=$ROOTFS_SIZE
    
    info "Formatting new rootfs as ext4"
    mkfs.ext4 "$BUILD_DIR/rootfs.ext4"

    sudo losetup -fP "$BUILD_DIR/rootfs.ext4"
    local LOOP_DEVICE=`losetup -a | grep -i "rootfs.ext4" | awk -F ':' '{print $1}'`

    mkdir "$BUILD_DIR/new_rootfs"
    debug sudo mount -t ext4 "$LOOP_DEVICE" "$BUILD_DIR/new_rootfs"
    sudo mount -t ext4 "$LOOP_DEVICE" "$BUILD_DIR/new_rootfs"

    info "Adding content to new root filesystem"
    sudo chown -R root:root "$ROOTFS_BUILD_DIR"
    sudo rsync -va "$ROOTFS_BUILD_DIR/" "$BUILD_DIR/new_rootfs"

    info "Unmount and remove temp device"
    sudo umount "$BUILD_DIR/new_rootfs"
    sudo losetup -d "$LOOP_DEVICE"

    info "Creating new rootfs archive..."
    cd "$BUILD_DIR" && tar -cvf - "rootfs.ext4" | gzip --best > "$BUILD_DIR/rootfs.ext4.tar.gz" && cd -
}