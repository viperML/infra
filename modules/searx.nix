{
  pkgs,
  config,
  ...
}: let
  localPort = 8001;
in {
  services.searx = {
    enable = true;
    environmentFile = config.sops.secrets.searx.path;
    settings = {
      server.port = localPort;
      server.bind_address = "0.0.0.0";
      server.secret_key = "@SEARX_SECRET_KEY@";
      engines = [
        {
          name = "google";
          shotcut = "g";
          engine = "google";
        }
      ];
    };
  };

  services.nginx.virtualHosts."searx.ayats.org" = {
    enableACME = true;
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://localhost:${localPort}/";
    };
  };

  sops.secrets.searx = {
    sopsFile = ../.secrets/searx.yaml;
  };
}
