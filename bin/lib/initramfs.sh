
function initramfs_build {
    initramfs_setup_env

    cp "$ALPINE_DIR/boot/initramfs-rpi4" "$INITRAMFS_BUILD_DIR"
    
    info "Extracting initramfs-rpi4"
    
    startDebug
    cd $INITRAMFS_BUILD_DIR && zcat initramfs-rpi4 | cpio -idmv && cd -
    endDebug
    
    info "Removing stock initramfs-rpi4 ($INITRAMFS_BUILD_DIR/initramfs-rpi4)"
    rm -f "$INITRAMFS_BUILD_DIR/initramfs-rpi4"

    info "Adding custom init script"
    mv "$INITRAMFS_BUILD_DIR/init" "$INITRAMFS_BUILD_DIR/init2"
    rm -f "$INITRAMFS_BUILD_DIR/init"
    cp "$ROOT/etc/init" "$INITRAMFS_BUILD_DIR/init"
    #cp "$ROOT/etc/init2" "$INITRAMFS_BUILD_DIR/init2"
    chmod +x "$INITRAMFS_BUILD_DIR/init"

    info "Adding custom busybox binary with tftp support..."
    startDebug
    curl -L "$BUSYBOX_DOWNLOAD_URL" > "$INITRAMFS_BUILD_DIR/bin/busybox" 
    chmod +x "$INITRAMFS_BUILD_DIR/bin/busybox"
    endDebug

    initramfs_package
}

function initramfs_setup_env {
    rm -rf "$BUILD_DIR"  "$ALPINE_DIR"
    mkdir -p "$ALPINE_DIR" "$BUILD_DIR" "$INITRAMFS_BUILD_DIR" 

    if [ ! -f "$ALPINE_KERNEL" ];
    then
        info "Downloading alpine rpi kernel ($ALPINE_DOWNLOAD_URL_KERNEL)"
        startDebug
        curl -L "$ALPINE_DOWNLOAD_URL_KERNEL" -o "$ALPINE_KERNEL"
        endDebug
    fi

    if [ -z "$(ls -A $ALPINE_DIR)" ];
    then
        info "Extracting alpine kernel (ALPINE_KERNEL)"
        startDebug
        tar -C "$ALPINE_DIR" -xvf "$ALPINE_KERNEL"
        endDebug
    fi
}

function initramfs_package {
    info "Creating new initramfs-rpi4 ($BUILD_DIR/initramfs-rpi4)"
    rm -f "$BUILD_DIR/initramfs-rpi4"
    
    startDebug
    cd "$INITRAMFS_BUILD_DIR" && find . | cpio -ov --format=newc | gzip --best > "$BUILD_DIR/initramfs-rpi4" && cd -
    endDebug
}