# Root File System

As a starting point 2 things will be needed, the minimal root file system downloadable from the alpine website and the kernel modules.
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

Next lets install some packages that are handy to use (and don't take up to much space).  

First make sure name resolution works:

```console
ifconfig
udhcpc -i enp6s0 -f -q
```

Now install some stuff:

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
    syslog-ng-openrc

rc-update add modules
rc-update add sshd
rc-update add zram-init
rc-update add fcron
rc-update add syslog-ng boot
```

Now set the root password:

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

Set the host name:

```console
hostname power.crazyzone.be
echo "power.crazyzone.be" > /etc/hostname
```

Create the interfaces file:

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
wget -O /sbin/zram-init 'https://raw.githubusercontent.com/vaeth/zram-init/main/sbin/zram-init.in'  && chmod +x /sbin/zram-init
```

OpenRC configuration:

```
echo "cgroup /sys/fs/cgroup cgroup defaults 0 0" >> /etc/fstab

cat > /etc/cgconfig.conf <<EOF
mount {
  cpuacct = /cgroup/cpuacct;
  memory = /cgroup/memory;
  devices = /cgroup/devices;
  freezer = /cgroup/freezer;
  net_cls = /cgroup/net_cls;
  blkio = /cgroup/blkio;
  cpuset = /cgroup/cpuset;
  cpu = /cgroup/cpu;
}
EOF
```

Enable USB:

```console
echo "ftdi_sio" >> /etc/modules
```

Configure logrotate:

```console
cat > /etc/logrotate.d/power.conf <<EOF
/var/log/* {
    daily
    rotate 2
    missingok
    compress
    copytruncate
}
EOF
```

### K3s Installation

Now add the script that will add K3s.

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
    "master": "https://kvm.crazyzone.be:6443",
    "token": "K10603fa719c8b6b49c1e6d6c4709f2a13de2ea2a8ea7140779afa664be2616f510::server:480128f36fedfdbd12cbb0bc2b5c89eb",
    "node_name": "power.crazyzone.be"
}
EOF
```

Now the actual script:

```console
cat > /bin/power-startup << EOF
#!/bin/sh

#echo "Initializing environment"
#/etc/init.d/networking restart

#fix the time
#ntpd -q -p pool.ntp.org

#make sure the USB devices are detected
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

Set the node password:

```console
mkdir -p /etc/rancher/node
echo "7e4dee6768d0c6b4af9cb277e02028fe" > /etc/rancher/node/password
```

## Creating the Disk Image

NOw that the new root file system has been created, an ext4 image needs to be created that will service as our file system.

Create the disk image:

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

```
sudo umount ~/rootfs/new_root_final
sudo losetup -d <device>
```

Package the file into a `.tar.gz` so it's less data to transfer:

```console
tar cvf - ./rootfs.ext4 | gzip --best > rootfs.ext4.tar.gz
```

Now place this file on your `TFTP` server:

```console
cp rootfs.ext4.tar.gz <tftp_root>/<pi id>/rootfs.ext4.tar.gz
```

Start up the PI.

## Cluster configuration

Once the node is added to the cluster, make sure to set the taint and affinities.

```console
kubectl taint nodes power.crazyzone.be type=power:NoSchedule
kubectl label nodes power.crazyzone.be type=power
```
