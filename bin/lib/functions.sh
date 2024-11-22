. "$ROOT/bin/lib/settings.sh"
. "$ROOT/bin/lib/log.sh"
. "$ROOT/bin/lib/initramfs.sh"
. "$ROOT/bin/lib/rootfs.sh"
. "$ROOT/bin/lib/dist.sh"
. "$ROOT/bin/lib/requirements.sh"


function build_cache {
    rm -rf "$ROOTFS_BUILD_DIR"
    mkdir -p "$BUILD_DIR" "$ROOTFS_BUILD_DIR"

    if [ ! -f "$ALPINE_ROOTFS" ];
    then
        info "Downloading alpine root filesystem ($ALPINE_DOWNLOAD_URL_ROOTFS)"
        startDebug
        curl -o "$ALPINE_ROOTFS" "$ALPINE_DOWNLOAD_URL_ROOTFS"
        endDebug
    fi

    if [ -z "$(ls -A $ROOTFS_BUILD_DIR)" ];
    then
        info "Extracting alpine root filesystem ($ALPINE_ROOTFS) to $ROOTFS_BUILD_DIR"
        startDebug
        tar -C "$ROOTFS_BUILD_DIR" -xvf "$ALPINE_ROOTFS"
        endDebug
    fi

    if [ ! -f "$TEMP/busybox" ];
    then
        info "Downloading custom busybox with tftp support ($BUSYBOX_DOWNLOAD_UR)"
        startDebug
        curl -o "$TEMP/busybox" "$BUSYBOX_DOWNLOAD_URL"
        chmod +x "$TEMP/busybox"
        endDebug
    fi
}