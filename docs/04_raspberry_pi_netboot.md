# Netboot

The Raspberry PI 3B+ or higher does not use `PXE` boot but it is possible to `netboot` it.  
For this you'll need access to your `DHCP` server configuration and have a `TFTP` server available.  

The `TFTP` server used in this project is `tftpd-hpa`.

I won't go into details of how to set up the `DHCP` server here, there are plenty of resources available on the NET for that.

Download the alpine Raspberry PI kernel from [the alpine website](https://www.alpinelinux.org/downloads/)

Put the contents in the root of your `TFTP` server.  
Optionally everything besides the `bootcode.bin` can be placed in a sub directory with as name the PI's serial number.  

To get the PI's serial number run:

```console
cat /sys/firmware/devicetree/base/serial-number
```

If that doesn't work you can also see the serial number in:

```console
cat /proc/cpuinfo
```

The serial field contains it.

The 8 last digest are the serial number that can be used as a directory name.  
This is handy for when there are multiple PI's that need to boot from the network and they have different `cmd.txt` or `config.txt`.

In my case I ended up with:

```
├── 3c8da5af
│   ├── bcm2710-rpi-2-b.dtb
│   ├── bcm2710-rpi-3-b.dtb
│   ├── bcm2710-rpi-3-b-plus.dtb
│   ├── bcm2710-rpi-cm3.dtb
│   ├── bcm2710-rpi-zero-2.dtb
│   ├── bcm2711-rpi-400.dtb
│   ├── bcm2711-rpi-4-b.dtb
│   ├── bcm2711-rpi-cm4.dtb
│   ├── bcm2837-rpi-3-a-plus.dtb
│   ├── bcm2837-rpi-3-b.dtb
│   ├── bcm2837-rpi-3-b-plus.dtb
│   ├── bcm2837-rpi-cm3-io3.dtb
|   └── boot
|       └── ...
│   ├── cmdline.txt
│   ├── config.txt
│   ├── fixup4.dat
│   ├── fixup.dat
|   └── overlays
|       └── ...
│   ├── start4.elf
│   └── start.elf
├── bootcode.bin
```

## Enable `Netboot` on the Raspberry PI 3B+

For this an SDCard will still be needed, start up the PI and update the `config.txt` file:

```
vim /boot/config.txt
```

Add `program_usb_boot_mode=1` under `[all]` if not already preset and reboot the PI.  

Once it's reboot it can be shut down and the next boot without an SDCard inserted should yield a network boot.  
This can also be done using the `UI` both options should work.  

When these steps are done the PI should net boot and go into a kernel panic of recovery console.  
This is because it's trying to mount a local root file system.

Edit the `cmdline.txt` with:

```
modules=loop,squashfs,sd-mod,usb-storage console=tty1 noquiet overlaytmpfs=yes cgroup_memory=1 cgroup_enable=memory
```

## Enable `NetBoot` on the Raspberry PI 4

Follow the steps from:

https://linuxhit.com/raspberry-pi-pxe-boot-netbooting-a-pi-4-without-an-sd-card/