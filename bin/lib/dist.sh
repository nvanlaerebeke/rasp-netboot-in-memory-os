
function dist {
    sudo rm -rf "$DIST_DIR" 

    info "Adding base alpine boot files"
    cp -R "$ALPINE_DIR" "$DIST_DIR"
    
    info "Adding custom initramfs..."
    rm -f "$DIST_DIR/boot/initramfs-rpi4"
    cp "$BUILD_DIR/initramfs-rpi4" "$DIST_DIR/boot/initramfs-rpi4"

    info "Adding rootfs..."
    cp "$BUILD_DIR/rootfs.ext4.tar.gz" "$DIST_DIR"

    if [ ! -z "$HTTP_SOURCE" ];
    then
        CMD_LINE_OPTION="$CMD_LINE_OPTION ROOTFS_HTTP=$HTTP_SOURCE" >> "$DIST_DIR/cmdline.txt"
        return
    fi

    if [ ! -z "$TFTP_HOST" ] && [ ! -z "$TFTP_PATH" ]
    then
        CMD_LINE_OPTION="$CMD_LINE_OPTION ROOTFS_TFTP_HOST=$TFTP_HOST ROOTFS_TFTP_FILE=$TFTP_PATH" >> "$DIST_DIR/cmdline.txt"
        return
    fi
    info "Using startup command '$CMD_LINE_OPTION'"
    info "$CMD_LINE_OPTION" > "$DIST_DIR/cmdline.txt"
}