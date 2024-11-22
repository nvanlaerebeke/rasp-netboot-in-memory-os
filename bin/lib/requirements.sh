function requirements {
    local PACKAGES=( "curl" "wget" "cpio" "squashfs-tools" "rsync" "qemu-user" "qemu-user-static" )
    
    # Loop through each package and check if it's installed
    for package in "${PACKAGES[@]}"; do
        if dpkg -l | grep -q "^ii  $package"; then
            info "$package is installed"
        else
            info "Installing requirements"
            install_requirements
        fi
    done
}

function install_requirements {
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
    
    startDebug
    apt update
    apt install -y curl wget cpio squashfs-tools rsync qemu-user qemu-user-static 
    endDebug
}
