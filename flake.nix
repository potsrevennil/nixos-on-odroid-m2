{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
  };
  description = "Build image";
  outputs = { self, nixpkgs, nixos-hardware, ... }:
    let
      system = "x86_64-linux";
      x86_64pkgs = nixpkgs.legacyPackages.${system};

      aarch64system = "aarch64-linux";
      pkgs = x86_64pkgs;
      # aarch64pkgs = nixpkgs.legacyPackages.${aarch64system};
    in
    rec {

      nixosConfigurations.odroid-m1s = nixpkgs.lib.nixosSystem
        {
          system = "${aarch64system}";
          modules = [
            <nixpkgs/nixos/modules/installer/sd-card/sd-image-aarch64.nix>
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
              ];
              nixpkgs.hostPlatform.system = aarch64system;
            })
            (
              { pkgs, config, ... }:

              let
                # linux-rockchip = { fetchFromGitHub, buildLinux, config, ... } @ args:
                #   buildLinux (args // rec {
                #     version = "6.7.0";
                #     src = fetchFromGitHub {
                #       # Fork of https://github.com/LeeKyuHyuk/linux
                #       owner = "torvalds";
                #       repo = "linux";
                #       rev = "v6.7";
                #       hash = "sha256-HC/IOgHqZLBYZFiFPSSTFEbRDpCQ2ckTdBkOODAOTMc=";
                #     };
                #     version = "6.6.8";
                #     src = fetchFromGitHub {
                #       # Fork of https://github.com/LeeKyuHyuk/linux
                #       owner = "ldicarlo";
                #       repo = "linux";
                #       rev = "v1";
                #       hash = "sha256-d51m5bYES4rkLEXih05XHOSsAEpFPkIp0VVlGrhSrnc=";
                #     };
                #     modDirVersion = version;
                #     kernelPatches = [ ];

                #     extraConfig = ''
                #       '';
                #     #extraMeta.platforms = [ "aarch64-linux" ];
                #     extraMeta.branch = "${version}";
                #   } // (args.argsOverride or { }));
                # linux_rchp = pkgs.callPackage linux-rockchip { };
              in
              {
                imports = [
                  ./kboot-conf
                ];
                boot.loader.kboot-conf.enable = true;
                nix.package = pkgs.nixFlakes;
                # boot.kernelPackages = pkgs.recurseIntoAttrs (pkgs.linuxPackagesFor linux_rchp);
                # system.boot.loader.kernelFile = "bzImage";
                boot.kernelParams = [ "console=ttyS2,1500000" ];
                hardware.deviceTree.enable = true;
                hardware.deviceTree.name = "rk3566-odroid-m1s.dts";
                hardware.deviceTree.dtbSource = ./dts;
                system.stateVersion = "23.11";
                sdImage = {
                  compressImage = false;

                  populateFirmwareCommands =
                    let
                      configTxt = pkgs.writeText "README" ''
                        Nothing to see here. This empty partition is here because I don't know how to turn its creation off.
                      '';
                    in
                    ''
                      cp ${configTxt} firmware/README
                    '';
                  populateRootCommands = ''
                    ${config.boot.loader.kboot-conf.populateCmd} -c ${config.system.build.toplevel} -d ./files/kboot.conf
                  '';
                };
              }
            )

          ];

        };
      images.odroid-m1s = nixosConfigurations.odroid-m1s.config.system.build.sdImage;
      devShells.x86_64-linux.default = x86_64pkgs.mkShell {
        buildInputs = with x86_64pkgs;
          [ ];
      };
    };
}
