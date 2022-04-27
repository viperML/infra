{
  config,
  pkgs,
  lib,
  ...
}: {
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  services.fail2ban = {enable = true;};

  services.nginx = {
    enable = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
  };

  security.acme = {
    acceptTerms = true;
    certs =
      builtins.mapAttrs (__: _: {
        email = "ayatsfer@gmail.com";
      })
      config.services.nginx.virtualHosts;
  };

  services.postgresql = {
    enable = true;
  };

  systemd = {
    timers.docker-prune = {
      wantedBy = ["timers.target"];
      partOf = ["docker-prune.service"];
      timerConfig.OnCalendar = "*-*-* 2:00:00";
    };
    services.docker-prune = {
      serviceConfig.Type = "oneshot";
      script = ''
        ${pkgs.docker}/bin/docker image prune --filter "until=72h"
      '';
      requires = ["docker.service"];
    };
  };

  services.tailscale.enable = true;

  services.openssh = {
    enable = true;
    listenAddresses = [
      {
        addr = "100.92.179.121";
        port = 22;
      }
    ];
  };
}
