{ lib, buildUBoot, rkbin, uboot-src, ... }:
buildUBoot {
  extraMakeFlags = [
    "ROCKCHIP_TPL=${rkbin}/bin/rk35/rk3588_ddr_lp4_2112MHz_lp5_2400MHz_v1.18.bin"
  ];
  extraMeta = {
    platforms = [ "aarch64-linux" ];
    license = lib.licenses.unfreeRedistributableFirmware;
  };
  src = uboot-src;
  version = uboot-src.rev;
  defconfig = "odroid-m2-rk3588s_defconfig";
  filesToInstall = [
    "u-boot.bin"
    "u-boot-rockchip.bin"
    "idbloader.img"
    "u-boot.itb"
  ];
  BL31 = "${rkbin}/bin/rk35/rk3588_bl31_v1.48.elf";
}
