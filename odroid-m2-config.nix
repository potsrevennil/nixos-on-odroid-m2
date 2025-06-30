{ pkgs, nixos-hardware, disko, nixpkgs, uboot, ... }:
{
  imports = [
    disko.nixosModules.disko
    "${nixos-hardware}/rockchip"
    "${nixos-hardware}/rockchip/disko.nix"
  ];

  nix = {
    package = pkgs.nixVersions.stable;
    nixPath = [ "nixpkgs=${nixpkgs}" ];
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    supportedFilesystems = pkgs.lib.mkForce [ "btrfs" "vfat" "ext2" ];
    kernelParams = [ "debug" "console=ttyS2,1500000" ];
    initrd.availableKernelModules = [
      "nvme"
      "nvme-core"
    ];
  };

  hardware = {
    deviceTree = {
      enable = true;
      name = "rockchip/rk3588s-odroid-m2.dtb";
    };
    rockchip = {
      enable = true;
      platformFirmware = pkgs.lib.mkDefault uboot;
    };

  };

  system.stateVersion = "25.05";

  networking.networkmanager.enable = true;

  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "yes";
  };

  users = {
    users.root = {
      extraGroups = [ "networkmanager" ];
      initialPassword = pkgs.lib.mkForce "odroid";
    };
  };
}
