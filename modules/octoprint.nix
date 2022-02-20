{ config, pkgs, ... }:
{
  services = {
    octoprint = {
      enable = true;
      plugins = (plugins: with plugins; [
        telegram
      ]);
    };

    mjpg-streamer.enable = true;
  };

}
