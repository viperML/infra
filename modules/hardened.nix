{
  config,
  pkgs,
  modulesPath,
  ...
}:
# https://dataswamp.org/~solene/2022-01-13-nixos-hardened.html
{
  imports = ["${modulesPath}/profiles/hardened.nix"];

  systemd.coredump.enable = false;

  services.clamav.daemon.enable = true;
  services.clamav.updater.enable = true;
}
