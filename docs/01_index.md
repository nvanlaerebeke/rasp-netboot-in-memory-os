# Raspberry PI - Linux In Ram

## Minimum Requirements

The minimum requirements are:

- Raspberry PI 3B to support network boot
- Raspberry PI 4 when running a k3s agent (3B only has 1GB ram)
- A network cable, WIFI support can easily be added but not included in these docs

## End Goal

The result should be a Raspberry PI that uses a `TFTP` server provided by the `DHCP` server to fetch the required resources and root file system.  

This root file system will contain [Alpine Linux](https://www.alpinelinux.org/) with all the services required to connect to it using `SSH` and to keep it running (example logrotate, ntp, ...)

Once the operating system has started it should automatically download and install [k3s](https://k3s.io/) kubernetes distribution and join the cluster.  

Resources that need to be deployed on this node can then be added to the cluster using taints, toleration and affinity.

## Index

- [Alpine Linux](02_alpine_linux.md)
- [Raspberry PI network boot](03_raspberry_pi_netboot.md)
- [Initramfs](04_initramfs.md)
- [Root filesystem](05_rootfs.md)
- [K3s](06_k3s_configuration.md)
- [Development environment](07_development_environment.md)
