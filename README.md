################################################################

This project is not maintained anymore - left for reference only

################################################################

# Tiny Core Linux Extension for Vintage Mac Target Display Mode

Well, if you ended up here, you're propably running Linux on a Vintage Mac and trying to enable Target Display Mode.

Luckily enough, Florian Echtler did some research on the topic and shared his improvements to
[smc_util](https://github.com/floe/smc_util/) several years ago.

I had myself already used my dated 27" 2009 iMac for several years in target display mode,
simply because it has a nice display and it would be shame to throw away.

However, the hard drive died recently, so I was trying to make it boot Linux from a USB thumb drive
to enable target display mode on the go.

# The Problem

Well, one thing that really bothered me was the need to install a full-blown operating system to simply run as a dumb display.
But even the smallest Debian or Ubuntu weigh-in at several hundred MiB, which is too much bloat. I wanted something small.

# The Solution

This is where [Tiny Core Linux](http://tinycorelinux.net/) comes into play!

It's well maintained, and in it's smallest incarnation less than 30 MiB, just about enough to boot up and run a few scripts.
So the idea was born.

To see an actual walk-through and system demo, checkout my videos
 * [iMac Target Display Mode using Linux](https://www.youtube.com/watch?v=hnRjJ6PVjic)
 * (only available from Dec/3rd/2022 5:00pm GMT+1) [News on Linux Target Display Mode 1.1 on vintage iMac [... and a hard drive swap fest]](https://www.youtube.com/watch?v=km37qu-NFz0)

# Technical Approach

This repository packages a bunch of scripts and other modifications, a `Dockerfile` and EFI boot loader, to assist you
not only building a package file for Tiny Core Linux, but to also assemble everything together for a bootable USB thumb drive,
that you can boot off your vintage Mac.

The bootable image is extended in the following ways:

 * a new package called `tdm` ("target display mode"), containg a custom compiled version of `smc_util`, is included
 * helper scripts are included in this package:
   * `/etc/init.d/services/tdm` as an init-style script, which accepts `start|stop|restart` keywords
   * `/usr/bin/tdm_on`, `/usr/bin/tdm_off` and `/usr/bin/tdm_toggle`, which can be used for turning Target Display Mode on/off or toggling it between states.
 * an automated startup trigger is installed at `/usr/local/tce.installed/tdm`, to switch Target Display Mode automatically on
 * `/etc/inittab` is modified to run `tdm_toggle`, `tdm_on` and `tdm_off` and `tdm_shutdown` scripts via the virtual terminals 2-5 (see also hot keys, further below) 


## Staging a Docker container as a Build Environment

I based this off Docker, to stage the build environment for the Tiny Core Linux extension inside a container environment.

Start as follows:
 
```
git clone https://github.com/gpdm/tinycore-targetdisplaymode.git
cd tinycore-targetdisplaymode 
sudo docker build . -t tcbuild
``` 


## Run the build inside the container

Now that your container was built, create an `output` directory, then simply run the container.

```
sudo docker run -it --rm -v `pwd`/output:/tmp/output tcbuild
```

This will run all necessary steps to

 * download the [smc_util](https://github.com/floe/smc_util/) source and compile it
 * download [Tiny Core Linux](http://tinycorelinux.net/) release 13 ISO
 * package the smc_util as a TCE extension package
 * restage the Tiny Core Linux ISO file into a custom respin
 * copy all files with the necessary structure to the `output` directory

Pay close attention to the build process. It's verbose, but there's not much error checking,
so it may fail at any time in the future (i.e. outdated download links, and such).

If it succeeds, you should have something like this in your `output` directory:

```
output/
output/boot
output/boot/grub
output/boot/grub/README.MD
output/boot/grub/grub.cfg
output/efi
output/efi/boot
output/efi/boot/bootX64.efi
output/boot-isos
output/boot-isos/Core-remastered.iso
```

## Run the build with a different TinyCore ISO file

By default, `http://tinycorelinux.net/13.x/x86/release/TinyCore-current.iso` is downloaded as the most
compact version of TinyCore Linux, which weights only some ~20 MiB.

You may of course use a different release, or a different image.
For this purpose, the container supports `TC_ISO_URL` environment variable,
which will be processed by the `build.sh` script.

If you want to use the more generous Tiny Core Plus image, you could specify it like this:

```
sudo docker run -it --rm -v `pwd`/output:/tmp/output \
	-e TC_ISO_URL=http://www.tinycorelinux.net/13.x/x86/release/CorePlus-current.iso \
	tcbuild
```

## Creating a Bootable USB thumb drive

Now take any USB thumb drive, and proceed as follows:

 * Initialize the thumb drive with an *GPT* partition table (don't use MBR style)
 * create a single FAT32 partition
 * the label of that FAT32 partition *must be* `TINYCORE`
 * Copy all files from the `output` directory directly into the root directory of the USB thumb drive 

(i) The thumb drive should be no less than 64 MiB, but also not bigger. Everything above 64 MiB works of course, but is simply a waste.


### Initalizing the USB drive in MacOS Terminal

Check out the device list using `diskutil list` command, whereas you'll get something like this:

```
<shortened for brevity>

/dev/disk3 (external, physical):
   #:                       TYPE NAME                    SIZE       IDENTIFIER
   0:     FDisk_partition_scheme                        *4.0 GB     disk3
   1:                 DOS_FAT_32 USBVOLUME               4.0 GB     disk3s1
```

This stick is having an MBR-type partition type, so it needs to be reinitialized.

! Be very careful here to not accidentally format the wrong drive !

Here's a sample command line for `/dev/disk3`:

```
diskutil partitionDisk /dev/disk3 1 GPT MS-DOS TINYCORE 0
```

The above would initialize the drive as follows:

 * GPT partition table
 * creates one hidden EFI partition
 * creates one MS-DOS/FAT32 partition
 * sets a label "TINYCORE" (important: keep this volume label, or auto-detection for system boot WILL FAIL!)
 * and fills all available disk space to the max

Upon reinspection, you will see something like this with the `diskutil list /dev/disk3` command:

```
/dev/disk3 (external, physical):
   #:                       TYPE NAME                    SIZE       IDENTIFIER
   0:      GUID_partition_scheme                        *4.0 GB     disk3
   1:                        EFI EFI                     209.7 MB   disk3s1
   2:       Microsoft Basic Data TINYCORE                3.8 GB     disk3s2
```

Please note, that the availability of the `EFI` partition depends on the size of your USB key.
For anything less than 2 GiB in size, no EFI partition will be created, hence your partitioning scheme will something like this:

```
/dev/disk3 (external, physical):
   #:                       TYPE NAME                    SIZE       IDENTIFIER
   0:      GUID_partition_scheme                        *2.1 GB     disk3
   1:       Microsoft Basic Data TINYCORE                2.1 GB     disk3s1
```

That's totally fine, the boot loader will take care for these different partition layouts.


### Example of files contained on the USB drive

Then copy everything within the `output` directory directly into to the USB root directory.
It should look like this:

![USB contents](./docs/USB_contents.png)

## How to Use

Well, once you have prepared your USB thumbdrive and copied all files over,
insert it into your iMac. Make sure that your second system is already wired-up with the graphics cable.
Then power your iMac on.

 * Press OPTION (ALT) key during power on. You should get several icons, one showing up as "EFI Boot".
   Select this one to boot.

 * You'll be presented with the GRUB boot menu.

 * Choose "Detect and show boot methods" option and hit ENTER.

 * After a few moments, you should get new options on display.
   * select the one reading `Target Display Mode (TinyCore, Auto-Detect USB Key)` and press ENTER

 * It should take a few seconds to boot up. Be patient and don't panic when it stalls for 10 seconds.
   That's because the system waits for the USB to settle.

 * Eventually, the extensions should be loaded.
 
 * If your second system is wired up (it should!), the iMac will automatically switch into Target Display Mode.
   If no system is connected, you may loose your display, as it may still turn black. DON'T PANIC and read along below!


### Switching Between Display Modes

Behold, you can use shortcuts to switch between display modes!

| Keystroke | Description |
| --- | --- |
| CTRL+ALT+F1, press <ENTER> | Bring up the system default console (will only be available if Target Display Mode was disabled) |
| CTRL+ALT+F2, press <ENTER> | Toggle between Target Display Mode and Local Display Mode. This is most similar in behaviour to Apples CMD+F2 key stroke. |
| CTRL+ALT+F3, press <ENTER> | This will turn on Target Display Mode, and your iMac should now act as a secondary display to your other Mac. |
| CTRL+ALT+F4, press <ENTER> | This will turn off Target Display Mode, and your iMac should show the local Linux console. |
| CTRL+ALT+F5, press <ENTER> | Shutdown and power-off the iMac |


## Customizations
	
This section covers potential areas, thay may require modifications in some situations.

### Device Auto Detection in grub.cfg

The configuration as seen fits well for my own purpose.
There might be cases, where it actually has to be adapted to your specific environments.

One of the more obvious ones is [grub.cfg](files/grub/grub.cfg), which contains the
boot instructions for Tiny Core Linux.

Please read the extra [readme](files/grub/README.md) for details concerning
the device auto detection.

Nevertheless it shall be mentioned here:
It's all depending on the USB Key having a volume label called 'TINYCORE'.
If you call the volume something different, it will not work, and auto-detection and booting WILL FAIL.


### Boot Loader

This repository includes a general purpose GRUB boot loader from [Super Grub2 Disk](https://www.supergrubdisk.org/super-grub2-disk/)
for EFI64 systems. This is at least compatible to iMac 2009 and later models.

There may be cases, where this does not work and a 32bit EFI loader is needed.
This can also be found on the same location, however I can make no guarantee that it actually works,
as I had never tested this.

	
## FAQ
	
### I have screen flickering or a blank screen
	
Check the display cable connection between your two machines.
Check the cable is properly and firmly inserted.

### I see nothing but a blank screen

See previous answer.
Maybe try turning Target Display Mode off and on again, using either the keyboard shortcuts as described above, or via the various helper scripts `sudo tdm_off`, `sudo tdm_on` or `sudo tdm_toggle`.

### Does this work on all Macs?

In theory, yes, it should.
But I couldn't test it, as I own myself only a 2009 iMac.

At least on all modell series between ~2009 and ~mid 2014, Apple claims
that Target Display Mode is supported.

Check out the [Apple Knowledge Base](https://support.apple.com/en-us/HT204592) on this topic.
	
### Why should I use this approach? MacOS does it already!

Sure. As I mentioned, I went into this topic simply because my hard drive died, and I thought about just booting off USB instead.
I just didn't want to install a fullblown OS for getting this rather simple job done.

### I got boot error complaining something about "device / partition not found"
	
This could happen given the way how grub.cfg boot entries were managed in the 1.0 release.
Please see the [old FAQ](https://github.com/gpdm/tinycore-targetdisplaymode/blob/1.0/README.md#i-got-boot-error-complaining-something-about-device--partition-not-found) as a reference.

In the 1.1 release, device auto-detection is performed and you should actually not encounted this issue any longer.
Beware though that auto-detection only works correctly if the USB volume label is set to `TINYCORE`.
	
### TDM does not automatically turn on on boot

Well, it should, unless cables aren't properly seated anyway.
However, when you are on the Linux console, run the `/usr/bin/tdm_toggle` toggle command manually and see what happens.

If you get an error like "file not found", the packages were not properly installed.
This is indicative to the partition scheme, or, more likely, a wrong volume label (see FAQ item above for more details).


### Help, I get "Target Display Mode: ioperm failed: Operation not permitted"

This error was seen only in the release 1.0.
See the [old FAQ](https://github.com/gpdm/tinycore-targetdisplaymode/blob/1.0/README.md#help-i-get-target-display-mode-ioperm-failed-operation-not-permitted) as a reference.

In release 1.1, this was fixed by having the helper utilities always perform privileges elevation internally. 
So, in essence, you can call them like this (in release 1.0, this was mandatory):

`sudo tdm_toggle`
	
`sudo tdm_on`
	
`sudo tdm_off`


Since release 1.1, it also works without the `sudo`, i.e. like so:

`tdm_toggle`
	
	
### I get a "failed in waitforX" error!

This error was seen only in the release 1.0.
See the [old FAQ](https://github.com/gpdm/tinycore-targetdisplaymode/blob/1.0/README.md#i-get-a-failed-in-waitforx-error) as a reference.
As noted there, the issue was because X11 is not enabled, and thus the error is not really an error, but expected behaviour.

In release 1.1, this misleading "error" message was thus removed. 


### How to properly shutdown?

Since the operating system loads everything to a RAM disk, you can simply turn the iMac off.

Or, if you want to do it cleanly, either run `poweroff` or `tdm_shutdown` from the system console,
or use the ALT+(Fn)+F5 + [ENTER] "hotkey" combo, to shutdown and power off.


### But it's still an iMac. How much is the power consumption?

Apple has published [power consumption](https://support.apple.com/en-us/HT201918) figures on their website.

As this is a full-blown computer, running in Target Display Mode will still consume a lot more power than
an ordinary monitor.
Es an example, the late 2009 iMac I have is reported with 104W Idle consumption.
I measured this myself and saw the same power consumption.

So, just be aware, it eats a lot of power!
A monitor is way better at this, especially if you leave it on permanently!


### Can't power consumption be furtherly reduced?

The iMac is already quiet efficient at conserving power.
Nevertheless, `cpupower` was incorporate to force the CPU into a low-frequency power conservation mode.

Also, `hdparm` is run to put the system hard drive `/dev/sda` into sleep mode.

According to my measurements on the late-2009 iMac, it doesn't decrease the power conspumption a lot.
I saw a very minimal reduction of ~8 Watts.


### Can I connect a Windows Machine to the iMac in Target Display Mode?

In short: Yes.

But it strongly depends on the adapter and cable.

Beware that most adapters converting to another display connector standard, are
intended only to be connected to the "computer-side", and not to the display-sode (the iMac acting in Target Display Mode in this case).

#### Example 1

You have a HDMI (male) to Display Port Adapter (female), and a Display Port (male) to Display Port (male) cable.

This might work, if the HDMI to Display Adapter is connected to your computer (and not the iMac).


#### Example 2

You have Display Port (or Mini-DP) male ti Mini-DP male cable.
This is what I had tested with, and I can confirm this definitely works.


#### Example 3

You have a HDMMI (male) to HDMI (male) cable, and a HDMI (female) to Display Port (male) adapter.

This will not work, if the Display Port adapter is connected to the iMac in Target Display Mode instead your computer.
 

As a rule of thumb: Straigth cables are propably the most hassle-free.
Adapters may work, if they're on the computer-side, and not the display-side.

I'd be happy to hear about anyone succeeding with other cable and adapter setups.


### Some iMacs report "send_byte(0x52, 0x0300) fail: 0x40" error

On some iMacs, an error like this may be reported, and as a consequence, Target Display Mode will simply not work.

```
send_byte(0x52, 0x0300) fail: 0x40
MVHR: read arg fail

read_smc get_key_type error
```

This was as well reported on the [upstream project](https://github.com/floe/smc_util/issues/2), with no solution currently available.


### Can I build this on Windows as well?

I did only test it on Windows 10 with WSL 2 using Ubuntu.
In short, yes, you can build it.

I didn't test though in WSL 1, or with other Linux distros. Though I don't see any reason, why it shouldn't work from a general point of view.



### I get a "Kernel too old" message during "docker build"

As the TinyCore ISO is unpacked in Docker for bootstrapping and compiling the tools and the image,
your host must be able to execute it.

The error simply means, that the TinyCore image expects a newer kernel version,
and your host system's kernel is in fact too old.

Please update to a newer kernel version on your host machine.


### How to control the brightness of the iMac running in Target Display Mode

As of today: Not possible.
The F1/F2 keys for controlling display brightness DO NOT WORK.

And you can't control the display brightness from the connected computer either.

Maybe I can find some time eventually to reverse engineer the SmcDumpKeys command
to figure out, which setting controls the display brightness.



## Attributions

 * Florian Echtler for [smc_util](https://github.com/floe/smc_util/)
 * The developers of [Super Grub2 Disk](https://www.supergrubdisk.org/super-grub2-disk/)
 * The developers of [Tiny Core Linux](http://tinycorelinux.net/) 

	
	
## To Do
	
 * assert compatibility for other iMacs (see also issue #9)
