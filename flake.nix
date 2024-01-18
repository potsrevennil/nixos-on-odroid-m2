{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    linux-rockchip.url = "github:LeeKyuHyuk/linux";
    linux-rockchip.flake = false;

  };
  description = "Build image";
  outputs = { self, nixpkgs, nixos-hardware, ... }:
    let
      system = "x86_64-linux";
      x86_64pkgs = nixpkgs.legacyPackages.${system};

      aarch64system = "aarch64-linux";
      pkgs = x86_64pkgs;
      aarch64pkgs = nixpkgs.legacyPackages.${aarch64system};
    in
    rec {
      nixosConfigurations.odroid-m1s = nixpkgs.lib.nixosSystem
        {
          system = "aarch64-linux";
          modules = [
            ({
              boot.kernelPackages =
                let
                  linux-rockchip = { fetchFromGitHub, buildLinux, ... } @ args:

                    buildLinux (args // rec {
                      version = "6.6.8";
                      modDirVersion = version;
                      src = fetchFromGitHub {
                        owner = "ldicarlo";
                        repo = "linux";
                        rev = "v1";
                        hash = "sha256-d51m5bYES4rkLEXih05XHOSsAEpFPkIp0VVlGrhSrnc=";
                      };
                      kernelPatches = [ ];

                      extraConfig = ''
                      '';
                      # extraMeta.platforms = [ "aarch64-linux" ];
                      extraMeta.branch = "6.6.8";
                    } // (args.argsOverride or { }));
                  linux_rchp = pkgs.callPackage linux-rockchip { };
                in
                pkgs.recurseIntoAttrs (pkgs.linuxPackagesFor linux_rchp);
              hardware.deviceTree.enable = true;
              hardware.deviceTree.filter = "rockchip/rk3566-odroid-m1s.dtb";
              sdImage.compressImage = false;
              system.stateVersion = "23.11";
            })
            <nixpkgs/nixos/modules/installer/sd-card/sd-image-aarch64.nix>
            {
              # nixpkgs.crossSystem.system = aarch64system;
              #  nixpkgs.config.allowUnsupportedSystem = true;
              nixpkgs.hostPlatform.system = aarch64system;
              # nixpkgs.buildPlatform.system = "x86_64-linux"; #If you build on x86 other wise changes this.
              # ... extra configs as above
              # virtualisation.vmVariant = {
              # following configuration is added only when building VM with build-vm
              #   virtualisation = {
              #     memorySize = 2048; # Use 2048MiB memory.
              #     cores = 3;
              #     graphics = false;
              #   };
              # };
            }
          ];

        };
      images.odroid-m1s = nixosConfigurations.odroid-m1s.config.system.build.sdImage;
      devShells.x86_64-linux.default = x86_64pkgs.mkShell {
        buildInputs = with x86_64pkgs;
          [ zstd ];
      };
    };
}
