{ config, pkgs, ... }:

let
  oci-getserver = pkgs.callPackage ../oci { };
in
{
  users.users.oci-getserver = {
    isSystemUser = true;
    group = "oci-getserver";
  };
  users.groups.oci-getserver = { };

  systemd = {
    services.oci-getserver = {
      serviceConfig.EnvironmentFile = [
        config.sops.secrets.oci.path
        config.sops.secrets.sendmail.path
      ];
      serviceConfig.Type = "oneshot";
      serviceConfig.ExecStart = "${oci-getserver}/oci-getserver.sh";
      path = [ pkgs.oci-cli pkgs.bash pkgs.curl ];
      serviceConfig.User = "oci-getserver";
      serviceConfig.Group = "oci-getserver";
    };
    timers.oci-getserver = {
      wantedBy = [ "timers.target" ];
      partOf = [ "oci-getserver.service" ];
      timerConfig.OnCalendar = "*:0/15";
    };
  };
}
