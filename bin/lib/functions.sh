. "$ROOT/bin/lib/settings.sh"
. "$ROOT/bin/lib/log.sh"
. "$ROOT/bin/lib/initramfs.sh"
. "$ROOT/bin/lib/rootfs.sh"
. "$ROOT/bin/lib/dist.sh"

function install_qemu_dependencies {
    if [ ! -f '/etc/os-release' ];
    then
        error "/etc/os-release does not exist, unknown OS, Make sure qemu-user-static is installed to run ARM binaries on x86"
    fi

    source "/etc/os-release"

    if [ -z "$NAME" ];
    then
        error "NAME not set in the os-release file"
    fi

    if [ "$NAME" != "Ubuntu" ];
    then
        error "operating system $NAME is not 'Ubuntu'"
    fi

    info "Installing requirements to execute ARM excutables"
    exec sudo apt install qemu-user qemu-user-static
}