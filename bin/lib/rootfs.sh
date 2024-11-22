
function rootfs_build {
    info "Adding custom changes to alpine mini root filesystem..."

    mkdir -p \
        "$ROOTFS_BUILD_DIR/etc/udev/rules.d/" \
        "$ROOTFS_BUILD_DIR/etc/network" \
        "$ROOTFS_BUILD_DIR/etc/periodic/hourly/" \
        "$ROOTFS_BUILD_DIR/etc/modprobe.d" \
        "$ROOTFS_BUILD_DIR/etc/modules-load.d/" \
        "$ROOTFS_BUILD_DIR/sbin" \
        "$ROOTFS_BUILD_DIR/etc/init.d" \
        "$ROOTFS_BUILD_DIR/init" \
        "$ROOTFS_BUILD_DIR/etc/" \
        "$ROOTFS_BUILD_DIR/bin"

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
    #cp "$ROOT/etc/cgconfig.conf" "$ROOTFS_BUILD_DIR/etc/cgconfig.conf"

    echo "BOOTSTRAP_LOCATION=$BOOTSTRAP_LOCATION" > "$ROOTFS_BUILD_DIR/etc/bootstrap.conf"

    rootfs_add_modules

    #echo "cgroup /sys/fs/cgroup cgroup defaults 0 0" >> "$ROOTFS_BUILD_DIR/etc/fstab"
    echo "ftdi_sio" >> "$ROOTFS_BUILD_DIR/etc/modules"

    #set up nameservers for apk install
    cat /etc/resolv.conf | grep nameserver > "$ROOTFS_BUILD_DIR/etc/resolv.conf"

    #setup inside the chroot
    info "Setting up the the rootfs using chroot"
    startDebug
    chroot "$ROOTFS_BUILD_DIR" /rootfs-setup.sh "$HOSTNAME" "$PASSWORD" "$SSH_PUB_KEY"
    endDebug

    #cleanup
    rm -f "$ROOTFS_BUILD_DIR/etc/resolv.conf" "$ROOTFS_BUILD_DIR/rootfs-setup.sh"

    rootfs_package
}

function rootfs_add_modules {
    startDebug
    unsquashfs -d "$BUILD_DIR/modules" "$ALPINE_DIR/boot/modloop-rpi4"
    cp -R "$BUILD_DIR/modules/modules" "$ROOTFS_BUILD_DIR/lib/"
    endDebug
}

function rootfs_package {
    info "Creating new rootfs"
    startDebug
    dd if=/dev/zero of="$BUILD_DIR/rootfs.ext4" bs=1M count=$ROOTFS_SIZE
    endDebug
    
    info "Formatting new rootfs as ext4"
    startDebug
    mkfs.ext4 "$BUILD_DIR/rootfs.ext4"
    endDebug

    losetup -fP "$BUILD_DIR/rootfs.ext4"
    local LOOP_DEVICE=`losetup -a | grep -i "rootfs.ext4" | awk -F ':' '{print $1}'`

    mkdir "$BUILD_DIR/new_rootfs"
    mount -t ext4 "$LOOP_DEVICE" "$BUILD_DIR/new_rootfs"

    info "Adding content to new root filesystem"
    chown -R root:root "$ROOTFS_BUILD_DIR"
    
    startDebug
    rsync -va "$ROOTFS_BUILD_DIR/" "$BUILD_DIR/new_rootfs"
    endDebug

    info "Unmount and remove temp device"
    umount "$BUILD_DIR/new_rootfs"
    losetup -d "$LOOP_DEVICE"

    info "Creating new rootfs archive..."
    startDebug
    cd "$BUILD_DIR" && tar -cvf - "rootfs.ext4" | gzip --best > "$BUILD_DIR/rootfs.ext4.tar.gz" && cd -
    endDebug
}