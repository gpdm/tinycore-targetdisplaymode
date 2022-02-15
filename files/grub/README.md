# GRUB config

This config item registers the remastered [TinyCore](http://tinycorelinux.net/) ISO file with a
loopback device, so it can be booted off the USB stick. 

The `iso=sdc2` instructs TinyCore where to look for the ISO files,
from where extensions are auto-installed during startup.
The partition number is a given when following the exact [instructions](../../README.md#creating-bootable-thumb-drive)
as outlined. If you use other means of partitioning, then device identifiers might be different,
and you need to adapt [grub.cfg](grub.cfg) accordingly.

(i) Please note, for my particular iMac, `sda` was the first harddrive, `sdb` the DVD drive,
    and `sdc` would become the USB stick. You may need to tweak this. 

The additional `waitusb=10` is required for the USB thumbdrive to be properly settled,
otherwise auto-installation of the packages may fail.

The `nodhcp` disables the DHCP agent, so the machine won't configure on the ethernet.
There's no reason for the machine to be connected to the network if it serves as a dummy display.

See [boot codes](http://www.tinycorelinux.net/faq.html#bootcodes) for additional kernel arguments.

```
menuentry "TinyCore Linux" {
 loopback loop (hd1,gpt1)/boot-isos/Core-remastered.iso
 linux (loop)/boot/vmlinuz waitusb=10 iso=sdc1 nodhcp
 initrd (loop)/boot/core.gz
}
```

