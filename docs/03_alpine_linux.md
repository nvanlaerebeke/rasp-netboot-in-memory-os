# Alpine

Why Alpine Linux?, because it's small and has a package manager to easily install additional software.  
If there is an even bigger space constraint `buildroot` can be used instead.

Extracted the Alpine root file system is 6MB, you'd be hard pressed to go lower than that even with `buildroot`.  
With `busybox` you can get as low as 1MB, most micro controllers have enough memory to host a 6MB root file system.  

Get the alpine root file system from their website [here](https://alpinelinux.org/downloads/).  
