{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    uboot-src = {
      flake = false;
      # url = "github:u-boot/u-boot"; # ?rev=866ca972d6c3cabeaf6dbac431e8e08bb30b3c8e";
      # url = "github:u-boot/u-boot";
      # url = "github:rockchip-linux/u-boot";
      url = "github:Kwiboo/u-boot-rockchip";
    };
  };
  description = "NixOS HardKernel Odroid M1S image";
  outputs = { self, nixpkgs, uboot-src, ... }:
    let
      aarch64system = "aarch64-linux";
      x86_64pkgs = import nixpkgs { system = "x86_64-linux"; config.allowUnfree = true; };
      aarch64pkgs = import nixpkgs { system = "aarch64-linux"; config.allowUnfree = true; };
      pkgs = x86_64pkgs;
      uboot = x86_64pkgs.pkgsCross.aarch64-multiplatform.buildUBoot rec {
        extraMakeFlags = [
          "ROCKCHIP_TPL=${aarch64pkgs.rkbin}/bin/rk35/rk3566_ddr_1056MHz_v1.21.bin"
        ];
        extraMeta = {
          platforms = [ "aarch64-linux" ];
          license = x86_64pkgs.lib.licenses.unfreeRedistributableFirmware;
        };
        src = uboot-src;
        version = uboot-src.rev;
        defconfig = "odroid-m1s-rk3566_defconfig";
        filesToInstall = [
          "u-boot.bin"
          # "u-boot-rockchip.bin"
        ];
        BL31 = "${aarch64pkgs.rkbin}/bin/rk35/rk3568_bl31_v1.44.elf";

      };
      # uboot = x86_64pkgs.pkgsCross.aarch64-multiplatform.buildUBoot rec {
      #   extraMakeFlags = [
      #     "ROCKCHIP_TPL=${aarch64pkgs.rkbin}/bin/rk35/rk3566_ddr_1056MHz_v1.21.bin"
      #   ];
      #   defconfig = "generic-rk3568_defconfig";
      #   extraMeta = {
      #     platforms = [ "aarch64-linux" ];
      #     license = x86_64pkgs.lib.licenses.unfreeRedistributableFirmware;
      #   };
      #   src = uboot-src;
      #   version = uboot-src.rev;
      #   filesToInstall = [
      #     "u-boot.itb"
      #     "idbloader.img"
      #     "u-boot-rockchip.bin"
      #     "spl/u-boot-spl.bin"
      #   ];
      #   # patches = [
      #   #   ./uboot/0001-wip.patch
      #   # ];
      #   # does not exist for rk3566 I think
      #
      # };


    in
    rec {
      nixosConfigurations.odroid-m1s = nixpkgs.lib.nixosSystem
        {
          system = "${aarch64system}";
          modules = [
            ({
              nixpkgs.overlays = [
                (final: super: {
                  makeModulesClosure = x:
                    super.makeModulesClosure (x // { allowMissing = true; });
                })
                (final: super: {
                  zfs = super.zfs.overrideAttrs (_: {
                    meta.platforms = [ ];
                  });
                })
                (self: super: {

                  uboot = super.uboot;
                })

              ];
              nixpkgs.hostPlatform.system = aarch64system;
            })
            (
              { lib, pkgs, config, ... }:
              {
                imports = [
                  (import "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
                    {
                      inherit config lib;
                      pkgs = import nixpkgs {
                        system = "${aarch64system}";
                        overlays = [
                          (self: super: {
                            uboot = super.uboot;
                          })
                        ];
                      };

                    })
                ];

                nix.package = pkgs.nixVersions.stable;
                nix.nixPath = [ "nixpkgs=${nixpkgs}" ];
                nix.extraOptions = ''
                  experimental-features = nix-command flakes
                '';
                boot.kernelPackages = pkgs.linuxPackages_latest;
                boot.supportedFilesystems = pkgs.lib.mkForce [ "btrfs" "cifs" "f2fs" "jfs" "ntfs" "reiserfs" "vfat" "xfs" "ext2" ];
                boot.kernelParams = [ "debug" "console=ttyS2,1500000" ];
                boot.initrd.availableKernelModules = [
                  "nvme"
                  "nvme-core"
                ];
                hardware.deviceTree.enable = true;
                hardware.deviceTree.name = "rockchip/rk3566-odroid-m1s.dtb";
                system.stateVersion = "25.05";
                sdImage = {
                  compressImage = false;
                  firmwareSize = 50;
                  populateFirmwareCommands = ''
                    cp ${uboot}/u-boot.bin firmware/
                  '';
                };

                services.openssh = {
                  enable = true;
                  settings.PermitRootLogin = "yes";
                };
                users.extraUsers.root.initialPassword = pkgs.lib.mkForce "odroid";
              }
            )

          ];

        };
      images.odroid-m1s = nixosConfigurations.odroid-m1s.config.system.build.sdImage;

      packages = rec {
        x86_64-linux.default = packages.all;

        all = pkgs.symlinkJoin {
          name = "all";
          paths = [ images.odroid-m1s ];
        };
      };

      devShells.x86_64-linux.default = x86_64pkgs.mkShell
        {
          buildInputs = with x86_64pkgs;
            [
              dtc
              minicom
              screen
              picocom
              usbutils
              zlib
              bison
              flex
              gcc
            ];
        };
    };

}



