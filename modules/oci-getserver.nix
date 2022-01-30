{ config, pkgs, ... }:
let
  oci-getserver = pkgs.callPackage ../oci { };
in
{
  sops.secrets = {
    oci = {
      sopsFile = ../.secrets/oci.yaml;
    };
    sendmail = {
      sopsFile = ../.secrets/sendmail.yaml;
    };
  };

  systemd = {
    services.oci-getserver = {
      serviceConfig.EnvironmentFile = [
        config.sops.secrets.oci.path
        config.sops.secrets.sendmail.path
      ];
      serviceConfig.Type = "oneshot";
      serviceConfig.ExecStart = "${oci-getserver}/oci-getserver.sh";
      serviceConfig.DynamicUser = true;
    };
  };
}
