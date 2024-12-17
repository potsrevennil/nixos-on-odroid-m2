This repository is based on https://github.com/sstent/nixos-on-odroid-m1/

It does not work for now.

Link in nixos'discourse: https://discourse.nixos.org/t/nixos-on-odroid-m1s

# Build image

`nix build ./\#images.odroid-m1s`

# Current status

It works!

# How-to

- Download `ODROID-M1S_EMMC2UMS.img` and `dd` it to a SD card
- `nix build ./`
- connect the micro usb cable to your computer and insert SD card with the mass storage mode in it
- `dd if=./result/sd-image/nixos-sd-image-[...] of=/dev/sdX status=progress`
- `dd if=./result/u-boot-rockchip.bin of=/dev/sdX bs=32k seek=1 conv=fsync`
- shutdown, remove the SD card, restart

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
