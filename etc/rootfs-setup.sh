#!/bin/busybox sh

#input
HOSTNAME=$1
PASSWORD=$2
SSH_PUB_KEY=$3

#make busybox symlinks
/bin/busybox --install -s /bin/

#install needed packages
/sbin/apk add --no-cache \
    vim \
    bash \
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

#add startup services
rc-update add modules
rc-update add networking
rc-update add sshd
rc-update add zram-init
rc-update add fcron
rc-update add syslog-ng boot
rc-update add bootstrap

#set root password
if [ ! -z "$PASSWORD" ];
then
    echo -e "$PASSWORD\n$PASSWORD" | passwd
else 
    passwd
fi

#add public ssh key if set
if [ ! -z "$SSH_PUB_KEY" ];
then
    mkdir -p /root/.ssh
    echo "$SSH_PUB_KEY" > /root/.ssh/authorized_keys
fi

#permit root login
echo "PermitRootLogin yes" >> /etc/ssh/sshd_config

#set hostname if provided
if [ ! -z "$HOSTNAME" ];
then
    hostname "$HOSTNAME"
    echo "$HOSTNAME" > /etc/hostname
fi

echo "chroot setup done"
