{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    uboot-src = {
      flake = false;
      url = "github:ldicarlo/u-boot-m1s";
    };
  };
  description = "Build image";
  outputs = { self, nixpkgs, uboot-src, nixos-hardware, ... }:
    let
      system = "x86_64-linux";
      x86_64pkgs = nixpkgs.legacyPackages.${system};

      aarch64system = "aarch64-linux";
      pkgs = x86_64pkgs;
      # aarch64pkgs = nixpkgs.legacyPackages.${aarch64system};
      uboot = (pkgs.buildUBoot {
        version = uboot-src.shortRev;
        src = uboot-src;
        defconfig = "odroid_m1s_defconfig";
        filesToInstall = [
          "u-boot.itb"
          "spl/u-boot-spl.bin"
        ];
      });
      # firmware = pkgs.stdenvNoCC.mkDerivation {
      #   name = "firmware-odroid-m1s";
      #   dontUnpack = true;
      #   nativeBuildInputs = [ pkgs.dtc pkgs.ubootTools ];
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
            [ dtc minicom screen picocom usbutils ];
        };
    };
}



