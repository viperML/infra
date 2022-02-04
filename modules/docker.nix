{ config, pkgs, ... }:
{
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
    storageDriver = "zfs";
    # extraOptions = "--registry-mirror=https://mirror.gcr.io --add-runtime crun=${pkgs.crun}/bin/crun --default-runtime=crun";
    extraOptions = "--registry-mirror=https://mirror.gcr.io";
  };

  users.groups.docker.members = config.users.groups.wheel.members;

  systemd = {
    timers.docker-prune = {
      wantedBy = [ "timers.target" ];
      partOf = [ "docker-prune.service" ];
      timerConfig.OnCalendar = "*-*-* 2:00:00";
    };
    services.docker-prune = {
      serviceConfig.Type = "oneshot";
      script = ''
        ${pkgs.docker}/bin/docker image prune --filter "until=72h"
      '';
      requires = [ "docker.service" ];
    };
  };

  fileSystems."/var/lib/docker" = {
    device = "zroot/data/docker";
    fsType = "zfs";
  };

  boot.kernelModules = [
    "bridge"
    "br_netfilter"
  ];
}
