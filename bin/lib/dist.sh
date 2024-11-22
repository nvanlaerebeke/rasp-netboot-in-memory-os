
function dist {
    rm -rf "$DIST_DIR" 

    info "Adding base alpine boot files"
    rsync -vva --delete "$ALPINE_DIR/" "$DIST_DIR"
    
    info "Adding custom initramfs..."
    rm -f "$DIST_DIR/boot/initramfs-rpi4"
    cp "$BUILD_DIR/initramfs-rpi4" "$DIST_DIR/boot/initramfs-rpi4"

    info "Adding rootfs..."
    cp "$BUILD_DIR/rootfs.ext4.tar.gz" "$DIST_DIR"

    if [ ! -z "$HTTP_SOURCE" ];
    then
        CMD_LINE_OPTION="ROOTFS_HTTP=$HTTP_SOURCE $CMD_LINE_OPTION"
    fi

    if [ ! -z "$TFTP_HOST" ] && [ ! -z "$TFTP_PATH" ]
    then
        CMD_LINE_OPTION="ROOTFS_TFTP_HOST=$TFTP_HOST ROOTFS_TFTP_FILE=$TFTP_PATH $CMD_LINE_OPTION"
    fi

    info "Using kernal startup command '$CMD_LINE_OPTION'"
    echo "$CMD_LINE_OPTION" > "$DIST_DIR/cmdline.txt"

    if [ -f "$ROOT/bootstrap.sh" ]; then
        info "Adding existing bootstrap.sh to the tftp root"r
        /bin/cp -f "$ROOT/bootstrap.sh" "$DIST_DIR/bootstrap.sh"
    fi
}