{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    nixos-hardware.url = "github:NixOS/nixos-hardware";

  };
  description = "Build image";
  outputs = { self, nixpkgs, nixos-hardware }:
    let
      system = "x86_64-linux";
      x86_64pkgs = nixpkgs.legacyPackages.${system};

      aarch64system = "aarch64-linux";
      aarch64pkgs = nixpkgs.legacyPackages.${aarch64system};
    in
    rec {
      nixosConfigurations.odroid-m1s = nixpkgs.lib.nixosSystem
        {
          modules = [
            ({
              boot.kernelPackages =
                ({ fetchurl, buildLinux, ... } @ args:

                  buildLinux (args // rec {
                    version = "6.6.8";
                    modDirVersion = version;

                    src = fetchurl {
                      url = "Github:LeeKyuHyuk/linux";
                      # After the first build attempt, look for "hash mismatch" and then 2 lines below at the "got:" line.
                      # Use "sha256-....." value here.
                      hash = "";
                    };
                    kernelPatches = [ ];

                    extraConfig = ''
                  '';

                    extraMeta.branch = "5.4";
                  } // (args.argsOverride or { }))
                );


              system.stateVersion = "23.11";
            })
            # imports = [ ];
            <nixpkgs/nixos/modules/installer/sd-card/sd-image-aarch64.nix>
            # <nixpkgs/nixos/modules/profiles/qemu-guest.nix>
            # <nixpkgs/nixos/modules/virtualisation/qemu-vm.nix>
            # <nixpkgs/nixos/modules/installer/sd-card/sd-image-raspberrypi.nix>
            nixos-hardware.nixosModules.hardkernel-odroid-hc4
            {
              # nixpkgs.crossSystem.system = aarch64system;
              #  nixpkgs.config.allowUnsupportedSystem = true;
              nixpkgs.hostPlatform.system = aarch64system;
              #  nixpkgs.buildPlatform.system = "x86_64-linux"; #If you build on x86 other wise changes this.
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
