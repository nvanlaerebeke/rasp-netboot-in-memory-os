# Development Environment

When creating and testing the root file system for ARM you need a way to quickly test the builds.  
With `QEMU` an `ARM` environment can be emulated so that it's easy and fast to test your changes.  

Additional for compiling and adding all the binaries cross compilation is a must.  

It's possible to do it on a Raspberry PI but it's very slow going.  
It's recommended to at least use a faster disk, example mount an `ISCSI` disk, does wonders for the PI.

## QEMU

For ARCH based systems follow the documentation here : https://wiki.archlinux.org/title/QEMU
For Debian based systems (Ubuntu etc) follow the documentation here: https://futurewei-cloud.github.io/ARM-Datacenter/qemu/how-to-launch-aarch64-vm/
For RHEL based systems (fedora etc) follow the documentation here: https://fedoraproject.org/wiki/Architectures/ARM/HowToQemu

## Cross Compile Environment

*To be documented*
