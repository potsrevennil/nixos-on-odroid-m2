{ nixos-hardware, disko, nixpkgs, ... }:
{ config, pkgs, ... }:
{
  imports = [
    disko.nixosModules.disko
    "${nixos-hardware}/rockchip"
    "${nixos-hardware}/rockchip/disko.nix"
  ];

  disko.devices.disk.main.imageSize = "3G";

  nix = {
    package = pkgs.nixVersions.stable;
    nixPath = [ "nixpkgs=${nixpkgs}" ];
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    supportedFilesystems = pkgs.lib.mkForce [ "bcachefs" "btrfs" "vfat" "ext2" ];
    kernelParams = [ "debug" "console=ttyS2,1500000" ];
    initrd.availableKernelModules = [
      "nvme"
      "nvme-core"
    ];
    loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
    };
  };

  hardware = {
    deviceTree = {
      enable = true;
      name = "rockchip/rk3588s-odroid-m2.dtb";
    };
    rockchip = {
      enable = true;
      platformFirmware = pkgs.lib.mkDefault pkgs.ubootOdroidM2;
      diskoExtraPostVM = ''
        dd if=${pkgs.ubootOdroidM2}/u-boot-rockchip.bin of=$out/${config.hardware.rockchip.diskoImageName} bs=32k seek=1 conv=notrunc,fsync
      '';
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
