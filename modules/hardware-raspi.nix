{ config, pkgs, modulesPath, ... }:
{
  imports = [
    "${modulesPath}/installer/sd-card/sd-image-aarch64.nix"
  ];

  networking.networkmanager = {
    enable = true;
  };

  users.groups.networkmanager.members = config.users.groups.wheel.members;

  extraModulePackages = with config.boot.kernelPackages; [
    rtl8192eu # wifi dongle
  ];
  blacklistedKernelModules = [ "rtl8xxxu" ];
}
