# Alpine

As a base operating system [Alpine Linux](https://www.alpinelinux.org/) will be used.

Why Alpine Linux?, because it's small and has a package manager to easily install additional software.  

The base root file system extracted available on the Alpine website is ~6MB, if there is an even bigger space constraint `buildroot`(starting ~1MB) can be used instead or a base `busybox`(~1MB) binary.  

The documentation here can be used to run `buildroot` and `busybox` but it is the intention to run `k3s` in memory, in that case the `kernel` and base file system size won't be the determining factor.  

Alpine is also officially supported by `k3s` while for the other methods manual changes might be needed.
