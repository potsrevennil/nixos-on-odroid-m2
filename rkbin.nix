{ rkbin, fetchFromGitHub, ... }:
rkbin.overrideAttrs (final: _: {
  version = "unstable-2025.01.24";
  src = fetchFromGitHub {
    owner = "rockchip-linux";
    repo = "rkbin";
    rev = "f43a462e7a1429a9d407ae52b4745033034a6cf9";
    hash = "sha256-geESfZP8ynpUz/i/thpaimYo3kzqkBX95gQhMBzNbmk=";
  };

  passthru = {
    BL31_RK3568 = "${final.finalPackage}/bin/rk35/rk3568_bl31_v1.44.elf";
    BL31_RK3588 = "${final.finalPackage}/bin/rk35/rk3588_bl31_v1.48.elf";
    TPL_RK3566 = "${final.finalPackage}/bin/rk35/rk3566_ddr_1056MHz_v1.23.bin";
    TPL_RK3568 = "${final.finalPackage}/bin/rk35/rk3568_ddr_1056MHz_v1.23.bin";
    TPL_RK3588 = "${final.finalPackage}/bin/rk35/rk3588_ddr_lp4_2112MHz_lp5_2400MHz_v1.18.bin";
  };
})

