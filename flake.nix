{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    uboot-src = {
      flake = false;
      url = "github:Kwiboo/u-boot-rockchip/rk3xxx-2025.01";
    };
  };
  description = "NixOS HardKernel Odroid M2 image";
  outputs = inputs@{ flake-parts, uboot-src, ... }: flake-parts.lib.mkFlake { inherit inputs; } {
    imports = [ ];
    systems = [ "aarch64-linux" "aarch64-darwin" ];
    perSystem = { pkgs, system, config, ... }:
      let
        wrapShell = mkShell: attrs:
          mkShell (attrs // {
            shellHook = ''
              export PATH=$PWD/scripts:$PATH
            '';
          });
      in
      {
        _module.args.pkgs = import inputs.nixpkgs {
          inherit system;
        };

        packages = {
          uboot = pkgs.buildUBoot {
            extraMakeFlags = [
              "ROCKCHIP_TPL=${pkgs.rkbin}/bin/rk35/rk3588_ddr_lp4_2112MHz_lp5_2736MHz_eyescan_v1.11.bin"
            ];
            src = uboot-src;
            version = uboot-src.rev;
            defconfig = "odroid-m2-rk3588s_defconfig";
            filesToInstall = [
              "u-boot.bin"
              "u-boot-rockchip.bin"
              "idbloader.img"
              "u-boot.itb"
            ];
            BL31 = "${pkgs.rkbin}/bin/rk35/rk3588_bl31_v1.47.elf";
          };

          nixosConfigurations.odroid-m2 = pkgs.lib.nixosSystem
            {
              system = system;
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
                      (import "${pkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix")
                    ];

                    nix.package = pkgs.nixVersions.stable;
                    nix.nixPath = [ "nixpkgs=${pkgs}" ];
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
                    hardware.deviceTree.name = "rockchip/rk3588s-odroid-m2.dtb";
                    system.stateVersion = "25.05";
                    sdImage = {
                      compressImage = false;
                      firmwareSize = 50;
                      populateFirmwareCommands = ''
                        cp ${config.packages.uboot}/u-boot.bin firmware/
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
          images.odroid-m2 = config.packages.nixosConfigurations.odroid-m2.config.system.build.sdImage;

          default = pkgs.symlinkJoin {
            name = "all";
            paths = [ config.packages.images.odroid-m2 config.packages.uboot ];
          };
        };

        devShells.default = wrapShell pkgs.mkShellNoCC {
          packages =
            builtins.attrValues {
              inherit (pkgs)
                direnv
                nix-direnv

                nixpkgs-fmt
                deadnix
                shfmt
                shellcheck
                taplo
                codespell

                dtc
                minicom
                screen
                picocom
                usbutils
                zlib
                bison
                flex
                gcc
                ;
            };
        };

      };
  };
}



