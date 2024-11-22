# Root File System

As a starting point two things will be needed, the minimal root file system downloadable from the alpine website and the kernel modules.  

For the kernel modules, copy them from the `tar.gz` extracted in the previous step (`initramfs`), it should be located in `./boot/modloop-rpi(4)`

## Root File System Files

Lets create a small disk image that will house it and our additional software:

```console
mkdir ~/rootfs
mkdir -p ~/rootfs/new_root

tar xvf alpine-minirootfs-3.15.4-aarch64.tar.gz -C ~/rootfs/new_root
```

Now `chroot` into the the directory:

```console
sudo chroot ~/rootfs/new_root /bin/busybox sh
```

First step is to let `busybox` create all the links for the applications:

```console
/bin/busybox --install -s /bin/
```

Now set the PATH environment variable:

```console
export PATH=$PATH:/sbin:/bin
```

Next install some packages that are handy to use (and don't take up to much space).  

First make sure name resolution works, update the `enp6s0` to match your machines interface name:

```console
ifconfig
udhcpc -i enp6s0 -f -q
```

Now install some services and packages.  
The services that are needed are:

- openrc: the init system (like systemd)
- zram: allows for memory compression
- fcron: needed for logrotate
- logrotate: to make sure our log files are cleaned up
- openssh: make the device reachable using SSH
- syslog-ng(-openrc): enable system logs
- modules: this makes it so kernel modules are loaded at boot

```console
/sbin/apk add --no-cache \
    vim \
    curl \
    openrc \
    jq \
    zram-init-openrc \
    cni-plugins \
    e2fsprogs \
    fcron \
    logrotate \
    openssh \
    syslog-ng \
    syslog-ng-openrc \
    dcron-openrc

rc-update add modules
rc-update add sshd
rc-update add zram-init
rc-update add fcron
rc-update add dcron
rc-update add syslog-ng boot
```

Set the root password:

```console
passwd
```

Add your public key if that's desired:

```console
mkdir -p /root/.ssh
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDVhd/xxIr4bVCuVTHZO6MwT5lJDtpD8c4u1vj/gRE36jk/k+gW2Ppf3i7QaOvO0yybgXy8dhwtFk+8vGziU17OTQo8zdFkkZrGD/KAxZ2tP+RpE3ZoHl+4Fa8qjTwWsSVP7tLfnLSOzyICWFSWe8udfgsBP92RLtKtARN7yLuIJGtE8AuSlIWBXBVm8uHoBqbNkeU237QcvBMye/IfRnlCTYuTZQ0AMJr5MTKwWOzeTnTbTQJjPuUSarPXui7bzw0M15bNfvuwAhc2q4FOBU5OGBjiqVMIou6olQomQnG8QKCXV60/853GpZtKVvVT6mzg7YbZbMNpPTL6slThjAYp" > /root/.ssh/authorized_keys
```

Enable root login:

```console
echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
```

Set the host name, update name to match your own setup:

```console
hostname power.crazyzone.be
echo "power.crazyzone.be" > /etc/hostname
```

Create the interfaces file, that way the network can be started:

```console
cat > /etc/network/interfaces << EOF
# The loopback network interface
auto lo
iface lo inet loopback
 
# The primary network interface
auto eth0
iface eth0 inet dhcp
EOF
```

Add the `NTP` update

```text
echo "/15	*	*	*	*	ntpd -d -q -n -p be.pool.ntp.org" >> /etc/crontabs/root
```

The raspberry PI is RAM constraint, for that the `zram` kernel extension can help a bit:

```console
mkdir -p /etc/udev/rules.d
echo "zram" > /etc/modules-load.d/zram.conf
echo "options zram num_devices=1" > /etc/modprobe.d/zram.conf
echo KERNEL=="zram0", ATTR{disksize}="250M",TAG+="systemd" > "/etc/udev/rules.d/99-zram.rules"
wget -O /sbin/zram-init 'https://raw.githubusercontent.com/vaeth/zram-init/main/sbin/zram-init.in' && chmod +x /sbin/zram-init
```

Enable the USB serial port support:

```console
echo "ftdi_sio" >> /etc/modules
```

### K3s Installation

Now add the script that will download and install K3s.  

This script will run at start and bootstrap the PI:

```console
cat > /etc/init.d/power << EOF
#!/sbin/openrc-run

READOUT_PID="/run/power.pid"

start() {
  ebegin "Starting environment"
  /bin/power-startup | tee /var/log/power-startup.log
  eend \$?
}
EOF
chmod +x /etc/init.d/power
rc-update add power
```

Add the cluster information:

```console
mkdir -p /etc/rancher
cat > /etc/rancher/master.json << EOF
{
    "master": "<master node>",
    "token": "<master token>
    "node_name": "<this nodes name>"
}
EOF
```

The token for the master is located by default at `/var/lib/rancher/k3s/server/token`.  
Add the contents of that file as the token value.  

The next script is the place where the actual work will be done, steps that it does:

- bring up the network
- make sure `ftdi_sio` module is loaded
- create the `tmpfs` storage for `k3s`
- download and install `k3s` and let it join the cluster

The reason for the `tmpfs` storage is due to the fact that containers cannot run on an `overlayfs` file system.  

Add the script:

```console
cat > /bin/power-startup << EOF
#!/bin/sh

#echo "Initializing environment"
#/etc/init.d/networking restart

#fix the time
#ntpd -q -p pool.ntp.org

#make sure the USB devices are detected (should already be done)
modprobe ftdi_sio

# Use a 1GB tmpfs to house the k3s:
TMPFS_MNT_POINTS=`mount  | grep rancher | wc -l`
if [ \$TMPFS_MNT_POINTS -eq 0 ];
then
    mkdir -p /var/lib/rancher
    mount -t tmpfs -o size=1000M tmpfs /var/lib/rancher
fi

export K3S_URL=\$(cat /etc/rancher/master.json | jq -r '.master')
export K3S_TOKEN=\$(cat /etc/rancher/master.json | jq -r '.token')
export K3S_NODE_NAME=\$(cat /etc/rancher/master.json | jq -r '.node_name')

curl -sfL https://get.k3s.io | K3S_URL=\$K3S_URL K3S_TOKEN=\$K3S_TOKEN K3S_NODE_NAME=\$K3S_NODE_NAME sh -
EOF
chmod +x /bin/power-startup
```

Set the node password to always be the same, otherwise on next start-up the agent will not be able to join the cluster again due to having a different password.

It's recommended to update the password here with a random other one for more security.

```console
mkdir -p /etc/rancher/node
echo "7e4dee6768d0c6b4af9cb277e02028fe" > /etc/rancher/node/password
```

## Creating the Disk Image

Now that the new root file system has been created, an ext4 image can be created that will service as our file system.

Create the disk image (500MB root file system):

```console
dd if=/dev/zero of=~/rootfs.ext4 bs=10M count=50
mkfs.ext4 ~/rootfs.ext4
```

Now it needs to be mounted:

```console
sudo losetup -fP ~/rootfs.ext4
```

Get the loop device name:

```console
losetup -a | grep -i rootfs
```

Mount it

```console
mkdir ~/rootfs/new_root_final
sudo mount /dev/loop<xx> ~/new_root_final
```

Rsync the content of the new_root to the actual disk:

```console
sudo rsync -va ~/new_root/* ~/new_root_final/
```

Now unmount and remove the loop device:

```console
sudo umount ~/rootfs/new_root_final
sudo losetup -d <device>
```

Package the file into a `.tar.gz` so it's less data to transfer over `TFTP`:

```console
tar cvf - ./rootfs.ext4 | gzip --best > rootfs.ext4.tar.gz
```

Now place this file on your `TFTP` server:

```console
cp rootfs.ext4.tar.gz <tftp_root>/<pi id>/rootfs.ext4.tar.gz
```

Start up the PI.
