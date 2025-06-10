{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    uboot-src = {
      flake = false;
      url = "github:Kwiboo/u-boot-rockchip/rk3xxx-2025.04";
    };
  };
  description = "NixOS HardKernel Odroid M2 image";
  outputs = { nixpkgs, uboot-src, ... }:
    let
      system = "aarch64-linux";
      pkgs = import nixpkgs { system = "aarch64-linux"; config.allowUnfree = true; };

      rkbin = pkgs.rkbin.overrideAttrs (_: {
        version = "unstable-2025.01.24";
        src = pkgs.fetchFromGitHub {
          owner = "rockchip-linux";
          repo = "rkbin";
          rev = "f43a462e7a1429a9d407ae52b4745033034a6cf9";
          hash = "sha256-geESfZP8ynpUz/i/thpaimYo3kzqkBX95gQhMBzNbmk=";
        };

        passthru = {
          BL31_RK3568 = "${rkbin}/bin/rk35/rk3568_bl31_v1.44.elf";
          BL31_RK3588 = "${rkbin}/bin/rk35/rk3588_bl31_v1.48.elf";
          TPL_RK3566 = "${rkbin}/bin/rk35/rk3566_ddr_1056MHz_v1.23.bin";
          TPL_RK3568 = "${rkbin}/bin/rk35/rk3568_ddr_1056MHz_v1.23.bin";
          TPL_RK3588 = "${rkbin}/bin/rk35/rk3588_ddr_lp4_2112MHz_lp5_2400MHz_v1.18.bin";
        };
      });

      uboot = pkgs.buildUBoot {
        extraMakeFlags = [
          "ROCKCHIP_TPL=${rkbin}/bin/rk35/rk3588_ddr_lp4_2112MHz_lp5_2400MHz_v1.18.bin"
        ];
        extraMeta = {
          platforms = [ "aarch64-linux" ];
          license = pkgs.lib.licenses.unfreeRedistributableFirmware;
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
      };
    in
    rec {
      nixosConfigurations.odroid-m2 = nixpkgs.lib.nixosSystem
        {
          system = "${system}";
          modules = [
            {
              nixpkgs.overlays = [
                (_: super: {
                  makeModulesClosure = x:
                    super.makeModulesClosure (x // { allowMissing = true; });
                })
                (_: super: {
                  zfs = super.zfs.overrideAttrs (_: {
                    meta.platforms = [ ];
                  });
                })
              ];
              nixpkgs.hostPlatform.system = system;
            }
            (
              { pkgs, ... }:
              {
                imports = [
                  (import "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix")
                ];

                nix = {
                  package = pkgs.nixVersions.stable;
                  nixPath = [ "nixpkgs=${nixpkgs}" ];
                  extraOptions = ''
                    experimental-features = nix-command flakes
                  '';
                };

                boot = {
                  kernelPackages = pkgs.linuxPackages_latest;
                  supportedFilesystems = pkgs.lib.mkForce [ "btrfs" "cifs" "f2fs" "jfs" "ntfs" "reiserfs" "vfat" "xfs" "ext2" ];
                  kernelParams = [ "debug" "console=ttyS2,1500000" ];
                  initrd.availableKernelModules = [
                    "nvme"
                    "nvme-core"
                  ];
                };

                hardware.deviceTree = {
                  enable = true;
                  name = "rockchip/rk3588s-odroid-m2.dtb";
                };

                system.stateVersion = "25.05";

                sdImage = {
                  compressImage = false;
                  firmwareSize = 50;
                  populateFirmwareCommands = ''
                    cp ${uboot}/u-boot.bin firmware/
                  '';
                  postBuildCommands = ''
                    dd if=${uboot}/u-boot-rockchip.bin of=$img bs=32k seek=1 conv=notrunc,fsync
                  '';
                };

                networking.networkmanager.enable = true;

                services.openssh = {
                  enable = true;
                  settings.PermitRootLogin = "yes";
                };

                users = {
                  users.root = {
                    extraGroups = [ "networkmanager" ];
                    initialPassword = pkgs.lib.mkForce "odroid";
                  };
                };
              }
            )
          ];
        };

      images.odroid-m2 = nixosConfigurations.odroid-m2.config.system.build.sdImage;

      packages = {
        aarch64-linux.default = packages.all;

        all = pkgs.symlinkJoin {
          name = "all";
          paths = [ images.odroid-m2 ];
        };
      };

      devShells.aarch64-linux.default = pkgs.mkShellNoCC { };
      devShells.aarch64-darwin.default =
        let
          pkgs = import nixpkgs { system = "aarch64-darwin"; config.allowUnfree = true; };
        in
        pkgs.mkShellNoCC {
          packages =
            builtins.attrValues {
              inherit (pkgs) minicom screen
                nixpkgs-fmt
                nixd
                deadnix
                statix;
            };
        };
    };
}



