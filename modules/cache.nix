{...}: let
  inherit (builtins) toString;
  nar-port = 8383;
  cache-port = 5000;
in {
  services.nar-serve = {
    enable = true;
    port = nar-port;
    cacheURL = "http://localhost:${toString cache-port}";
  };

  services.nix-serve = {
    enable = true;
    bindAddress = "localhost";
    port = cache-port;
  };

  # services.nginx.virtualHosts."cache.nix.ayats.org" = {
  #   enableACME = true; # Use ACME certs
  #   forceSSL = true; # Force SSL
  #   locations."/" = {
  #     proxyPass = "http://localhost:${toString cache-port}";
  #   };
  # };

  services.nginx.virtualHosts."nar.nix.ayats.org" = {
    enableACME = true; # Use ACME certs
    forceSSL = true; # Force SSL
    locations."/" = {
      proxyPass = "http://localhost:${toString nar-port}";
    };
  };

  security.acme.certs."nar.nix.ayats.org".server = "https://acme-staging-v02.api.letsencrypt.org/directory";
}
