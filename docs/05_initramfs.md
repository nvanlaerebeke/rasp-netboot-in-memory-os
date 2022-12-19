# Initramfs

The `initramfs` is the initial ram disk that will be loaded by the kernel.  
This is what will bring the system to a running state.  

In this case an extra step in the `initramfs` int script must be done, that is getting the root file system and making that the device being booted as there is no SD-card or hard drive present.  

The way it is gotten is using the same `TFTP` server used then for the network boot.  
Once the root file system is in ram it can be mounted and the root can be switch to that.

## Creating the `initramfs`

As a base, use the `initramfs` that came with the alpine kernel for the Raspberry PI, this can be downloaded from [the alpine website](https://www.alpinelinux.org/downloads/).  

Extract the file and in the `boot` directory there will be a `initramfs-rpi(4)` image.  
This is the one that will need to be modified.  

```console
mkdir unpacked
cp initramfs-rpi(4) unpacked
cd unpacked && zcat initramfs-rpi(4) | cpio -idmv
rm -f initramfs-rpi
```

Now rename the existing `init` file to `init2`:

```console
cd unpacked
mv init init2
```

Create a new `init` file that will get the root file system from the `TFTP` server that will be used before the `init2` is done.  

```console
cat > init << EOF
#!/bin/busybox sh

echo "Getting rootfs before the int starts..."
/bin/busybox mkdir -p \
    /usr/bin \
    /usr/sbin \
    /proc \:x
    /sys \
    /dev \
    $sysroot \
	/media/cdrom \
    /media/usb \
    /tmp \
    /run/cryptsetup

# Spread out busybox symlinks and make them available without full path
/bin/busybox --install -s
export PATH=/usr/bin:/bin:/usr/sbin:/sbin


[ -c /dev/null ] || mknod -m 666 /dev/null c 1 3

mount -t sysfs -o noexec,nosuid,nodev sysfs /sys
mount -t devtmpfs -o exec,nosuid,mode=0755,size=2M devtmpfs /dev 2>/dev/null \
	|| mount -t tmpfs -o exec,nosuid,mode=0755,size=2M tmpfs /dev

# Make sure /dev/kmsg is a device node. Writing to /dev/kmsg allows the use of the
# earlyprintk kernel option to monitor early init progress. As above, the -c check
# prevents an error if the device node has already been seeded.
[ -c /dev/kmsg ] || mknod -m 660 /dev/kmsg c 1 11

mount -t proc -o noexec,nosuid,nodev proc /proc
# pty device nodes (later system will need it)
[ -c /dev/ptmx ] || mknod -m 666 /dev/ptmx c 5 2
[ -d /dev/pts ] || mkdir -m 755 /dev/pts
mount -t devpts -o gid=5,mode=0620,noexec,nosuid devpts /dev/pts

# shared memory area (later system will need it)
[ -d /dev/shm ] || mkdir /dev/shm
mount -t tmpfs -o nodev,nosuid,noexec shm /dev/shm

clear

echo "Bringing up network"
INTERFACES=\$(ifconfig | wc -l)
while [ \$INTERFACES -eq 0 ];
do
    sleep 1
    ifconfig eth0 0.0.0.0 > /dev/null 2>&1
    INTERFACES=\$(ifconfig | wc -l)
done

sleep 5
udhcpc -i eth0 -f -q

SERIAL=\$(cat /proc/cpuinfo | grep Serial | awk '{print \$3}')
SUBDIR=\${SERIAL: -8}
tftp -g -r "\$SUBDIR/rootfs.ext4.tar.gz" kvm.crazyzone.be

if [ ! -f rootfs.ext4.tar.gz ];
then
    echo "Unable to find root filesystem, exiting to shell..."
    exec /bin/busybox sh
    exite
fi

tar xvf rootfs.ext4.tar.gz
rm rootfs.ext4.tar.gz

losetup -fP rootfs.ext4
sleep 1
DEVICE=\$(losetup -a | grep rootfs.ext4 | awk -F ':' '{print \$1}' | tr -d '\n')

echo "Found device \$DEVICE"
export KOPT_root=\$DEVICE

echo "Rootfs is available, unmounting..."

umount /sys
umount /dev/shm
umount /dev/pts
umount /dev
umount /proc

#export KOPT_init="/bin/busybox"
#export KOPT_init_args="sh"
exec /init2
EOF
chmod +x init
```

A different `busybox` binary will also be required as, the one provided in the alpine image does not have `TFTP` support.

Instead of compiling it ourselves it can be downloaded from the `busybox` website:

```console
curl -L 'https://www.busybox.net/downloads/binaries/1.31.0-defconfig-multiarch-musl/busybox-armv7l' > bin/busybox ; \
chmod +x bin/busybox
```

Now that everything is in place the image can be re-packed:

```console
sudo find . | sudo cpio -ov --format=newc | sudo gzip -9 >../initramfs 
```
