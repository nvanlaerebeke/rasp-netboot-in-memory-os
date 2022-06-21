# Netboot a Raspberry PI into Memory

This repository contains documentation on how to boot a Raspberry PI from network and run only from memory (no SD-card).  

This is ideal for many `IOT` devices for several reasons.  

- SD-cards are very unreliable and slow
- Having the root file system on `NFS` can break easily due to a simple network interruption

The solution presented here is ideal for a lot of `IOT` applications that do not need huge amounts of RAM.  

The minimum requirements are:

- Raspberry PI 3B to support network boot
- Raspberry PI 4 when running a k3s agent (3B only has 1GB ram)
- A network cable, WIFI support can easily be added but not included in these docs

[Continue reading here](./docs/01_index.md)
