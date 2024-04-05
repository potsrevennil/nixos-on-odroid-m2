This repository is based on https://github.com/sstent/nixos-on-odroid-m1/

It does not work for now.

Link in nixos'discourse: https://discourse.nixos.org/t/nixos-on-odroid-m1s

# Build image

`nix build ./\#images.odroid-m1s`


# Current status

Does not work:

see the content of ./screenlog.0 for more info

# Links

- U-Boot patch: https://patchwork.ozlabs.org/project/uboot/patch/20240125070252.2057679-1-tobetter@gmail.com/
- Linux patch: http://lists.infradead.org/pipermail/linux-rockchip/2024-January/044072.html
- RockChip instructions (maybe): https://opensource.rock-chips.com/wiki_Boot_option#U-Boot
- earlyprintk instructions:
  - https://wiki.st.com/stm32mpu/wiki/Dmesg_and_Linux_kernel_log#earlyprintk
  - https://docs.kernel.org/arch/x86/earlyprintk.html


# Maybe steps from https://opensource.rock-chips.com/wiki_Boot_option#U-Boot

`dd if=idbloader.img of=sdb seek=64`
`dd if=u-boot.itb of=sdb seek=16384`
`dd if=boot.img of=sdb seek=32768`
`dd if=rootfs.img of=sdb seek=262144`

# Other maybe steps

first as mass storage zero the beginning of the eMMC
`dd if=/dev/zero of=/dev/sda bs=8M count=1`

`cp result/sdimage tmp/sdimage`
`dd if=result/u-boot-rockchip.bin of=./tmp/nixos.img oflag=seek_bytes seek="$((0x8000))" conv=notrunc`

as mass storage
`dd if=/dev/zero of=/dev/sda bs=8M count=1`
`dd tmp/nixos.img`

## To reset
boot using uart then block boot
`mmc erase 0 0x4000`
then mass storage with sd is ok
