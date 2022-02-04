{ config, pkgs, ... }:
{
  networking.firewall.allowedTCPPorts = [
    80 443
  ];

  services.fail2ban = { enable = true; };

  services.nginx = {
    enable = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
  };

  security.acme = {
    acceptTerms = true;
    certs = {
      "git.ayats.org".email = "ayatsfer@gmail.com";
      "drone.ayats.org".email = "ayatsfer@gmail.com";
    };
  };

  services.postgresql = {
    enable = true;
  };

  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
    storageDriver = "zfs";
    extraOptions = "--registry-mirror=https://mirror.gcr.io --add-runtime crun=${pkgs.crun}/bin/crun --default-runtime=crun";
  };

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
}
