This repository is based on https://github.com/sstent/nixos-on-odroid-m1/

It does not work for now.

Link in nixos'discourse: https://discourse.nixos.org/t/nixos-on-odroid-m1s

# Build image

`nix build ./\#images.odroid-m1s`


# Current status

Does not work:

```
Wrong image format for "source" command
switch to partitions #0, OK
mmc1 is current device
Scanning mmc 1:1...
** Unable to read file / **
Scanning mmc 1:2...
Found /boot/extlinux/extlinux.conf
Retrieving file: /boot/extlinux/extlinux.conf
724 bytes read in 9 ms (78.1 KiB/s)
------------------------------------------------------------
1:      NixOS - Default
Enter choice: 1
1:      NixOS - Default
Retrieving file: /boot/extlinux/../nixos/s958q61dp67dwrixw6a0886aq5m7svcm-initrd-linux-6.7.5-initrd
11207872 bytes read in 944 ms (11.3 MiB/s)
Retrieving file: /boot/extlinux/../nixos/i0pwc8a0bwj3zqdajclcsqp8wnh3q0zn-linux-6.7.5-Image
64838144 bytes read in 15263 ms (4.1 MiB/s)
append: init=/nix/store/nkbmjxx3qsq0lin1n79l15w7h61n5qs5-nixos-system-nixos-24.05.20240223.cbc4211/init console=ttyS0,115200n8 console=ttyAMA0,115200n8 console=tty0 console=ttyS2,1500000 loglevel=7
Retrieving file: /boot/extlinux/../nixos/gfaha89vwafcwawz5y378i61mx7glg4w-dtbs/rockchip/rk3566-odroid-m1s.dtb
160974 bytes read in 31 ms (5 MiB/s)
Fdt Ramdisk skip relocation
No misc partition
## Flattened Device Tree blob at 0x08300000
   Booting using the fdt blob at 0x08300000
   Using Device Tree in place at 0000000008300000, end 000000000832a4cd
## reserved-memory:
  ramoops@110000: addr=110000 size=f0000
Adding bank: 0x00200000 - 0x08400000 (size: 0x08200000)
Adding bank: 0x09400000 - 0xf0000000 (size: 0xe6c00000)
Adding bank: 0x100000000 - 0x200000000 (size: 0x100000000)
Total: 19112.208/19157.23 ms

Starting kernel ...

I/TC: Secondary CPU 1 initializing
I/TC: Secondary CPU 1 switching to normal world boot
I/TC: Secondary CPU 2 initializing
I/TC: Secondary CPU 2 switching to normal world boot
I/TC: Secondary CPU 3 initializing
I/TC: Secondary CPU 3 switching to normal world boot


```
