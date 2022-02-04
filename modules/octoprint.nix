{ config, pkgs, ... }:
{
  services = {
    octoprint = {
      enable = true;
    };

    mjpg-streamer = {
      enable = true;
    };
  };
}
