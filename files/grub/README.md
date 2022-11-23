# GRUB config

The current grub.cfg implements device autodetection,
which works by searching for a USB key with a 'TINYCORE' volume label.

The boot action then registers the remastered [TinyCore](http://tinycorelinux.net/) ISO file with a
loopback device, so it can be booted off the USB stick. 

The `iso=LABEL=TINYCORE` instructs TinyCore where to look for the ISO files,
again by pointing at a drive with a 'TINYCORE' volume label.

The additional `waitusb=10` is required for the USB thumbdrive to be properly settled,
otherwise auto-installation of the packages may fail.

The `nodhcp` disables the DHCP agent, so the machine won't configure on the ethernet.
There's no reason for the machine to be connected to the network if it serves as a dummy display.

See [boot codes](http://www.tinycorelinux.net/faq.html#bootcodes) for additional kernel arguments.

```
# this is the auto-detecting boot mode
#
menuentry "Target Display Mode (TinyCore, Auto-Detect USB Key)" --id tdm_autoboot {

 # try detecting our TDM boot drive, by locating a device
 # with the TINYCORE label, which will be store into the
 # ${root} variable
 search --no-floppy --set=root --label TINYCORE

 echo "'Target Display Mode' boot device found at ${root}"
 echo -n "Booting in ... "
 sleep --verbose 3 

 # reflect ${root} variable to mount the ISO file as a loopback device
 loopback loop (${root})/boot-isos/Core-remastered.iso

 # reflect to iso= kernel argument for locating
 # the ISO file on this device during boot
 #
 # the following alternative syntax should work for UUID and LABEL:
 # iso=UUID=xxxx-yyyy
 # iso=LABEL=xyz
 #
 # as we don't know the UUID, the label is key for detecting it
 #
 linux (loop)/boot/vmlinuz waitusb=10 iso=LABEL=TINYCORE nodhcp
 initrd (loop)/boot/core.gz
}
```
