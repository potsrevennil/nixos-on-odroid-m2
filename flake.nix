{
  description = "NixOS HardKernel Odroid M2 image";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    uboot-src = {
      flake = false;
      url = "github:Kwiboo/u-boot-rockchip/rk3xxx-2025.04";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware.url = "github:NixOS/nixos-hardware";

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
  };
  outputs = inputs@{ flake-parts, uboot-src, ... }: flake-parts.lib.mkFlake { inherit inputs; } {
    imports = [ ./configuration.nix ];
    systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin" ];
    perSystem = { pkgs, lib, system, ... }:
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
          overlays = [
            (_:prev: lib.optionalAttrs prev.stdenv.isLinux {
              rkbin = prev.callPackage ./rkbin.nix { rkbin = prev.rkbin; };
              ubootOdroidM2 = prev.callPackage ./uboot.nix { inherit uboot-src; };
            })
          ];
        };

        devShells.default = wrapShell pkgs.mkShellNoCC {
          packages =
            builtins.attrValues {
              inherit (pkgs)
                direnv
                nix-direnv

                nixpkgs-fmt
                deadnix
                statix
                picocom
                ;
            };
        };

        packages = lib.optionalAttrs pkgs.stdenv.isLinux {
          default = inputs.self.nixosConfigurations.odroid-m2.config.system.build.diskoImages;
          diskoScript = inputs.self.nixosConfigurations.odroid-m2.config.system.build.diskoImagesScript;
        };
      };
  };
}
