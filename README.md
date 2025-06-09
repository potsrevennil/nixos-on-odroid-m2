This repository is based on https://github.com/ldicarlo/nixos-on-odroid-m1s

# Build Image

> ⚠️ Cross-compiling the Linux kernel on macOS doesn't work (yet).

You can build this on Linux (both **x86_64** and **aarch64**), but the Nix flake is currently set up only for **aarch64**.
It's easy to adjust if you want to build it on **x86_64** too.

Pre-built image files are available in [GitHub Releases](../../releases) if you don't want to build it yourself.

# How-to
## 1. Prepare SD card on macOS

Use `diskutil` to identify and unmount the SD card:

```bash
diskutil list            # Find your SD card device, e.g. /dev/disk3
diskutil unmountDisk /dev/disk3
```

## 2. Quick Boot Test (write image directly to SD card)

If you just want to see if the board boots correctly:

```bash
dd if=./result/sd-image/nixos-sd-image-[...] of=/dev/sdX status=progress
dd if=./result/u-boot-rockchip.bin of=/dev/sdX bs=32k seek=1 conv=fsync
```

To boot from the SD card, make sure to switch the boot mode from eMMC to microSD
(there's usually a boot select switch or jumper on the board — refer to the Odroid M2 manual).

Then insert the SD card into the Odroid M2, power it on, and see if it boots.

## 3. Install from USB (mass storage mode)

1. Download `ODROID-M2_EMMC2UMS.img` and write it to a spare SD card:

    ```bash
    dd if=ODROID-M2_EMMC2UMS.img of=/dev/sdx bs=4m status=progress
    ```

2. Insert this SD card into the Odroid and connect the **USB-C** cable to your computer. The eMMC should appear as a mass storage device.

3. Either build the image:

    ```bash
    nix build
    ```

    Or download a pre-built image from my [GitHub Releases](https://github.com/potsrevennil/nixos-on-odroid-m2/releases).

4. Write the NixOS image and U-Boot to the eMMC:

    ```bash
    dd if=./result/sd-image/nixos-sd-image-*.img of=/dev/sdX status=progress
    dd if=./result/u-boot-rockchip.bin of=/dev/sdX bs=32k seek=1 conv=fsync
    ```

5. Power off the board, remove the SD card, and restart. It should now boot from eMMC.

## To reset when bricked
boot using uart then block boot
`mmc erase 0 0x4000`
then mass storage with sd is ok

# Links

- U-Boot patch: https://patchwork.ozlabs.org/project/uboot/patch/20240125070252.2057679-1-tobetter@gmail.com/
- Linux patch: http://lists.infradead.org/pipermail/linux-rockchip/2024-January/044072.html
- RockChip instructions (maybe): https://opensource.rock-chips.com/wiki_Boot_option#U-Boot
- earlyprintk instructions:
  - https://wiki.st.com/stm32mpu/wiki/Dmesg_and_Linux_kernel_log#earlyprintk
  - https://docs.kernel.org/arch/x86/earlyprintk.html
- U-boot working version https://github.com/Kwiboo/u-boot-rockchip/tree/rk3xxx-2025.01
- instructions for u-boot https://github.com/jonesthefox/odroid-m1s-arch
- u-boot patches for m2 https://github.com/mth/u-boot-odroid-m2/tree/current
