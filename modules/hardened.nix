{ config, pkgs, modulesPath, ... }:
{
  imports = [ "${modulesPath}/profiles/hardened.nix" ];

  systemd.coredump.enable = false;

  services.clamav.daemon.enable = true;
  services.clamav.updater.enable = true;
}
