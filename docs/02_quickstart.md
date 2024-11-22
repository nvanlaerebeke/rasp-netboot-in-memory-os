# Quickstart

This quickstart assumes the network booting for the Raspberry PI is already set up.  
The netboot files for on the `tftp` server will be generated and will be available in `./dist` after the build is done.

If the Raspberry PI or `DHCP` isn't configured yet, follow the steps in [raspberry pi netboot](./04_raspberry_pi_netboot.md)

A build script is provided in `./bin/build.sh`, this script is made to run on `Ubuntu 20.04/22.04/24.04` or higher.

When running it the end result will be in `./dist`, this is the directory that needs to be put on the `tftp` server for netbooting.  
This includes all the files with the modified initramfs-rpi and the root filesystem.

## Configuration

First copy the `env.sample` to `env` and fill in the settings.  

The only required settings are the root filesystem location and bootstrap script location.  
This will be included in the `./dist` folder after the build, the file will be called `rootfs.ext4.tar.gz`.  
The quickest way to get started is to place this on the `tftp` server together with all the netboot files.  

If your `tftp` host is `tftp.example.com` and path is `d94a609b` fill it in as follows:

```console
TFTP_HOST=tftp.example.com
TFTP_PATH=d94a609b/rootfs.ext4.tar.gz
BOOTSTRAP_LOCATION=tftp://tftp.example.com/d94a609b/bootstrap.sh
```

## Bootstrap

The file on the `BOOTSTRAP_LOCATION` path is an `sh` script that will run once the `PI` has started.
An example script that installs `k3s` is included in the root:

```console
cp bootstrap.sh.example01 bootstrap.sh
```

Make sure to change the following parameters in the script to suite your needs:

```config
K3S_MASTER=https://master.example.com:6443
K3S_TOKEN= #token can be found in /var/lib/rancher/k3s/server/node-token
K3S_NODE_NAME=node.example.com
VERSION="v1.25.3+k3s1" #empty for latest
```

## Build

Building the content to put on the `TFTP` server can be done by using the included docker container.

To build the container image:

```console
make container
```

Now to use the container to build everything:

```console
make build
```

By default the output will be available in `./dist`, put this in the root of your `TFTP` server and boot your PI.  
