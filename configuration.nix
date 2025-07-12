{ inputs, withSystem, ... }:
{
  config.flake = {
    nixosConfigurations.odroid-m2 =
      withSystem "aarch64-linux" (ctx:
        inputs.nixpkgs.lib.nixosSystem
          {
            inherit (ctx) pkgs system;
            specialArgs = { inherit inputs; };
            modules = [
              (import ./hardware-configuration.nix {
                inherit (inputs) nixos-hardware disko nixpkgs;
              })
            ];
          });
  };
}

