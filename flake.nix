{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    #linux-rockchip.url = "github:LeeKyuHyuk/linux";
    #linux-rockchip.flake = false;

  };
  description = "Build image";
  outputs = { self, nixpkgs, nixos-hardware, ... }:
    let
      system = "x86_64-linux";
      x86_64pkgs = nixpkgs.legacyPackages.${system};

      aarch64system = "aarch64-linux";
      # pkgs = import nixpkgs {
      #   inherit system;

      #   overlays = [
      #     (final: super: {
      #       makeModulesClosure = x:
      #         super.makeModulesClosure (x // { allowMissing = true; });
      #     })
      #   ];
      # };

      pkgs = x86_64pkgs;
      # aarch64pkgs = nixpkgs.legacyPackages.${aarch64system};
    in
    rec {

      nixosConfigurations.odroid-m1s = nixpkgs.lib.nixosSystem
        {
          system = "aarch64-linux";
          modules = [
            <nixpkgs/nixos/modules/installer/sd-card/sd-image-aarch64.nix>
            ({
              nixpkgs.overlays = [
                (final: super: {
                  makeModulesClosure = x:
                    super.makeModulesClosure (x // { allowMissing = true; });
                })
              ];
              nixpkgs.hostPlatform.system = aarch64system;
            })
            (
              let
                linux-rockchip = { fetchFromGitHub, buildLinux, ... } @ args:
                  buildLinux (args // rec {
                    version = "6.6.8";
                    modDirVersion = version;
                    src = fetchFromGitHub {
                      # Fork of https://github.com/LeeKyuHyuk/linux
                      owner = "torvalds";
                      repo = "linux";
                      rev = "master";
                      hash = "sha256-d51m5bYES4rkLEXih05XHOSsAEpFPkIp0VVlGrhSrnc=";
                    };
                    kernelPatches = [ ];

                    extraConfig = ''
                      '';
                    #extraMeta.platforms = [ "aarch64-linux" ];
                    extraMeta.branch = "6.6.8";
                  } // (args.argsOverride or { }));
                linux_rchp = pkgs.callPackage linux-rockchip { };
              in
              {
                nix.package = pkgs.nixFlakes;
                boot.kernelPackages = pkgs.recurseIntoAttrs (pkgs.linuxPackagesFor linux_rchp);
                hardware.deviceTree.enable = true;
                hardware.deviceTree.name = "rockchip/rk3566-odroid-m1s.dtb";
                #hardware.deviceTree.dtbSource = ./dts;
                #sdImage.compressImage = false;
                system.stateVersion = "23.11";
              }
            )

          ];

        };
      images.odroid-m1s = nixosConfigurations.odroid-m1s.config.system.build.sdImage;
      devShells.x86_64-linux.default = x86_64pkgs.mkShell {
        buildInputs = with x86_64pkgs;
          [ zstd ];
      };
    };
}
