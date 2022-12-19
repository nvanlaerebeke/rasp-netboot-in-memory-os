
function dist {
    sudo rm -rf "$DIST_DIR" 

    echo "Adding base alpine boot files"
    cp -R "$ALPINE_DIR" "$DIST_DIR"
    
    echo "Adding custom initramfs..."
    rm -f "$DIST_DIR/boot/initramfs-rpi4"
    cp "$BUILD_DIR/initramfs-rpi4" "$DIST_DIR/boot/initramfs-rpi4"

    echo "Adding rootfs..."
    cp "$BUILD_DIR/rootfs.ext4.tar.gz" "$DIST_DIR"

    dist_read_remote_location_info
    dist_write_cmdline    
}

function dist_read_remote_location_info {
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

function dist_write_cmdline {
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



