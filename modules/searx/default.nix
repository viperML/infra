{
  pkgs,
  config,
  lib,
  ...
}: let
  inherit (builtins) toString;
  ports = {
    searx = 8001;
    oauth2 = 8002;
  };
  engines = import ./engines.nix;
in {
  services.searx = {
    enable = true;
    environmentFile = config.sops.secrets.searx.path;
    settings = {
      server = {
        port = ports.searx;
        bind_address = "127.0.0.1";
        secret_key = "@SEARX_SECRET_KEY@";
      };
      search = {
        autocomplete = "duckduckgo";
      };
      engines = lib.mkForce (
        [
          {
            name = "brave";
            shortcut = "brave";
            engine = "xpath";
            paging = false;
            search_url = "https://search.brave.com/search?q={query}";
            url_xpath = ''//div[@class="snippet fdb"]/a/@href'';
            title_xpath = ''//span[@class="snippet-title"]'';
            content_xpath = ''//p[1][@class="snippet-description"]'';
            suggestion_xpath = ''/div[@class="text-gray h6"]/a'';
            categories = "general";
            disabled = false;
          }
        ]
        ++ (map (name: {
            inherit name;
            tokens = ["@SEARX_DUMMY_TOKEN@"];
          })
          engines.hidden)
      );
    };
  };

  users.users.oauth2_proxy.group = "oauth2_proxy";
  users.groups.oauth2_proxy = {};

  services.oauth2_proxy = {
    enable = true;
    httpAddress = "http://127.0.0.1:${toString ports.oauth2}";
    upstream = "http://127.0.0.1:${toString ports.searx}";
    provider = "github";
    clientID = "11fc65f8a8bb6b81f791";
    keyFile = config.sops.secrets.searx.path;
    email.domains = ["gmail.com"];
  };

  services.nginx.virtualHosts."searx.ayats.org" = {
    enableACME = true;
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://localhost:${toString ports.oauth2}/";
    };
  };
  security.acme.certs."searx.ayats.org".email = "ayatsfer@gmail.com";

  sops.secrets.searx = {
    sopsFile = ../../.secrets/searx.yaml;
  };
}
