{ config, pkgs, modulesPath, lib, ... }:
{
  imports = [
    "${modulesPath}/installer/sd-card/sd-image-aarch64.nix"
  ];

  networking.networkmanager = {
    enable = true;
  };

  users.groups.networkmanager.members = config.users.groups.wheel.members;

  # nixpkgs.config.allowBroken = true;
  # boot = {
  #   extraModulePackages = with config.boot.kernelPackages; [
  #     rtl8192eu
  #   ];
  # };
}
