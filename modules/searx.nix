{
  pkgs,
  config,
  lib,
  ...
}: let
  localPort = 8001;
  disabledEngines = [
    "wikipedia"
    "archive is"
    "bing"
    "currency"
    "ddg definitions"
    "erowid"
    "wikidata"
    "etools"
    "etymonline"
    "gigablast"
    "library genesis"
    "qwant"
    "yahoo"
    "wiby"
    "wikibooks"
    "wikiquote"
    "wikisource"
    "wiktionary"
    "wikiversity"
    "wikivoyage"
    "dictzone"
    "mymemory translated"
    "duden"
    "seznam"
    "mojeek"
    "naver"
  ];
in {
  services.searx = {
    enable = true;
    environmentFile = config.sops.secrets.searx.path;
    settings = {
      server = {
        port = localPort;
        bind_address = "0.0.0.0";
        secret_key = "@SEARX_SECRET_KEY@";
      };
      search = {
        autocomplete = "duckduckgo";
      };
      engines = lib.mkForce ([
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
          }
        ]
        ++ (map (name: {
            inherit name;
            tokens = ["@SEARX_DUMMY_TOKEN@"];
          })
          disabledEngines));
    };
  };

  services.nginx.virtualHosts."searx.ayats.org" = {
    enableACME = true;
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://localhost:${builtins.toString localPort}/";
    };
  };
  security.acme.certs."searx.ayats.org".email = "ayatsfer@gmail.com";

  sops.secrets.searx = {
    sopsFile = ../.secrets/searx.yaml;
  };
}
