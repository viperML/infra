{ config, pkgs, ... }:
{
  services.octoprint = {
    enable = true;
  };

  services.avahi.enable = true;
  services.avahi.nssmdns = true;
}
