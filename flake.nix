{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    uboot-src = {
      flake = false;
      # url = "github:u-boot/u-boot?rev=83cdab8b2c6ea0fc0860f8444d083353b47f1d5c"; # this is the current nixos version of u-boot
      url = "github:ldicarlo/u-boot-m1s/uboot-m1s"; # this is the current version in nixos with the patch for the M1S
      # url = "github:rockchip-linux/u-boot";
    };
  };
  description = "Build image";
  outputs = { self, nixpkgs, uboot-src, nixos-hardware, ... }:
    let
      aarch64system = "aarch64-linux";
      x86_64pkgs = import nixpkgs { system = "x86_64-linux"; config.allowUnfree = true; };
      aarch64pkgs = import nixpkgs { system = "aarch64-linux"; config.allowUnfree = true; };
      pkgs = x86_64pkgs;
      uboot = x86_64pkgs.pkgsCross.aarch64-multiplatform.buildUBoot rec {
        extraMakeFlags = [
          "ROCKCHIP_TPL=${aarch64pkgs.rkbin}/bin/rk35/rk3566_ddr_1056MHz_v1.21.bin"
        ];
        defconfig = "odroid-m1s-rk3566_defconfig";
        extraMeta = {
          platforms = [ "aarch64-linux" ];
          license = x86_64pkgs.lib.licenses.unfreeRedistributableFirmware;
        };
        src = uboot-src;
        version = uboot-src.rev;
        filesToInstall = [ "u-boot-rockchip.bin" ];
        patches = [ ];
        BL31 = "${aarch64pkgs.rkbin}/bin/rk35/rk3568_bl31_v1.44.elf";
      };

      # firmware = pkgs.stdenvNoCC.mkDerivation {
      #   name = "firmware-odroid-m1s";
      #   dontUnpack = true;
      #   nativeBuildInputs = with pkgs; [ dtc ubootTools bison flex ];
      #   installPhase = ''
      #     runHook preInstall

      #     mkdir -p "$out/"

      #     cp ${uboot}/u-boot-spl.bin u-boot-spl.bin
      #     spl_tool -c -f ./u-boot-spl.bin

      #     install -Dm444 ./u-boot-spl.bin.normal.out $out/u-boot-spl.bin.normal.out
      #     install -Dm444 ${uboot}/u-boot.itb $out/odroid_m1s_payload.img

      #     runHook postInstall
      #   '';
      # };
    in
    rec {
      nixosConfigurations.odroid-m1s = nixpkgs.lib.nixosSystem
        {
          system = "${aarch64system}";
          modules = [
            # <nixpkgs/nixos/modules/installer/sd-card/sd-image-aarch64.nix>
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
                  uboot = super.callPackage uboot { };
                })

              ];
              nixpkgs.hostPlatform.system = aarch64system;
            })
            (
              { pkgs, config, ... }:

              let
                linux-rockchip = { fetchFromGitHub, buildLinux, config, ... } @ args:
                  buildLinux (args // rec {
                    #     version = "6.7.0";
                    #     src = fetchFromGitHub {
                    #       # Fork of https://github.com/LeeKyuHyuk/linux
                    #       owner = "torvalds";
                    #       repo = "linux";
                    #       rev = "v6.7";
                    #       hash = "sha256-HC/IOgHqZLBYZFiFPSSTFEbRDpCQ2ckTdBkOODAOTMc=";
                    #     };
                    version = "6.6.8";
                    src = fetchFromGitHub {
                      # Fork of https://github.com/LeeKyuHyuk/linux
                      owner = "ldicarlo";
                      repo = "linux";
                      rev = "v1";
                      hash = "sha256-d51m5bYES4rkLEXih05XHOSsAEpFPkIp0VVlGrhSrnc=";
                    };
                    modDirVersion = version;
                    kernelPatches = [ ];
                    extraConfig = ''
                          '';
                    extraMeta.platforms = [ "aarch64-linux" ];
                    extraMeta.branch = "${version}";
                  } // (args.argsOverride or { }));
                linux_rchp = pkgs.callPackage linux-rockchip { };
              in
              {
                imports = [
                  # ./kboot-conf
                  "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
                  ({
                    nixpkgs.overlays =
                      [
                        (self: super: {
                          uboot = super.callPackage uboot { };
                        })
                      ];
                  })
                ];
                boot.loader.grub.enable = false;
                # boot.loader.kboot-conf.enable = true;
                nix.package = pkgs.nixFlakes;
                nix.nixPath = [ "nixpkgs=${nixpkgs}" ];
                nix.extraOptions = ''
                  experimental-features = nix-command flakes
                '';
                # boot.kernelPackages = pkgs.linuxPackages_latest;
                boot.kernelPackages = pkgs.recurseIntoAttrs (pkgs.linuxPackagesFor linux_rchp);
                boot.supportedFilesystems = pkgs.lib.mkForce [ "btrfs" "cifs" "f2fs" "jfs" "ntfs" "reiserfs" "vfat" "xfs" ];
                # system.boot.loader.kernelFile = "bzImage";
                boot.kernelParams = [ "console=ttyS2,1500000" "debug" ];
                boot.initrd.availableKernelModules = [
                  "nvme"
                  "nvme-core"
                  "phy-rockchip-naneng-combphy"
                  "phy-rockchip-snps-pcie3"
                ];
                hardware.deviceTree.enable = true;
                hardware.deviceTree.name = "rockchip/rk3566-odroid-m1s.dtb";
                # hardware.deviceTree.dtbSource = ./dtbs;
                system.stateVersion = "24.05";
                sdImage = {
                  compressImage = false;
                  populateFirmwareCommands =
                    let
                      configTxt = pkgs.writeText "README" ''
                        '';
                    in
                    ''
                      cp ${configTxt} firmware/README
                    '';
                  # postBuildCommands = ''
                  #   dd if=${uboot}/u-boot-sunxi-with-spl.bin of=$img bs=1024 seek=8 conv=notrunc
                  # '';
                  # populateRootCommands = ''
                  #   ${config.boot.loader.kboot-conf.populateCmd} -c ${config.system.build.toplevel} -d ./files/kboot.conf
                  # '';
                };

                environment.systemPackages = [
                  pkgs.git #gotta have git
                ];


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



