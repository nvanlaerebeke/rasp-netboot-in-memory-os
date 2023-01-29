# Quickstart

This quickstart assumes the network booting for the Raspberry PI is already set up.  
The netboot files for on the `tftp` server will be generated and will be available in `./dist` after the build is done.

If the Raspberry PI or `DHCP` isn't configured yet, follow the steps in [raspberry pi netboot](./04_raspberry_pi_netboot.md)

A build script is provided in `./bin/build.sh`, this script is made to run on `Ubuntu 20.04/22.04` or higher.

When running it the end result will be in `./dist`, this is the directory that needs to be put on the `tftp` server for netbooting.  
This includes all the files with the modified initramfs-rpi4 and the root filesystem.

## Configuration

First copy the `env.sample` to `env` and fill in the settings.  

The only required setting is the root filesystem location.  
This will be included in the `./dist` folder after the build, the file will be called `rootfs.ext4.tar.gz`.  
The quickest way to get started is to place this on the `tftp` server together with all the netboot files.  

If your `tftp` host is `tftp.example.com` and path is `d94a609b` fill it in as follows:

```console
TFTP_HOST=tftp.example.com
TFTP_PATH=d94a609b/rootfs.ext4.tar.gz
```

## Build

To start the build, run:

```console
./bin/build.sh
```

## Testing

A python script that reads out the serial port (/dev/ttyUSB0) is included in the `src` directory.

Alternativly use the following python command:

```python
apk add --no-cache python3 py3-pip
pip3 install pyserial
python3 -m serial.tools.miniterm /dev/ttyUSB0 115200 --xonxoff
```
