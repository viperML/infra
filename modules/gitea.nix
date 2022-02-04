{ config, pkgs, ... }:
# https://mcwhirter.com.au/craige/blog/2019/Deploying_Gitea_on_NixOS/
{
  services.nginx.virtualHosts."git.ayats.org" = {
    enableACME = true; # Use ACME certs
    forceSSL = true; # Force SSL
    locations."/" = {
      proxyPass = "http://localhost:3001/";
    };
  };

  services.postgresql = {
    authentication = ''
      local gitea all ident map=gitea-users
    '';
    identMap = # Map the gitea user to postgresql
      ''
        gitea-users gitea gitea
      '';
  };

  sops.secrets."postgres/gitea_dbpass" = {
    sopsFile = ../.secrets/postgres.yaml;
    owner = config.users.users.gitea.name;
  };

  services.gitea = {
    enable = true;
    appName = "git.ayats.org gitea"; # Give the site a name
    database = {
      type = "postgres"; # Database type
      passwordFile = config.sops.secrets."postgres/gitea_dbpass".path;
    };
    domain = "git.ayats.org"; # Domain name
    rootUrl = "https://git.ayats.org/"; # Root web URL
    httpPort = 3001; # Provided unique port
    disableRegistration = true;
  };
}
