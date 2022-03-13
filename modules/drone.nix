{
  config,
  pkgs,
  ...
}:
# https://github.com/Mic92/dotfiles/blob/c71efec4ecbc8d5eb207b247cec2a8c435a06d6c/nixos/eve/modules/drone/server.nix
# https://docs.drone.io/server/provider/gitea/
let
  droneserver = config.users.users.droneserver.name;
in {
  users.users.droneserver = {
    isSystemUser = true;
    createHome = true;
    group = droneserver;
  };
  users.groups.droneserver = {};

  services.nginx.virtualHosts."drone.ayats.org" = {
    enableACME = true; # Use ACME certs
    forceSSL = true; # Force SSL
    locations."/".proxyPass = "http://localhost:3030/";
  };
  security.acme.certs."drone.ayats.org".email = "ayatsfer@gmail.com";

  services.postgresql = {
    ensureDatabases = [droneserver];
    ensureUsers = [
      {
        name = droneserver;
        ensurePermissions = {
          "DATABASE ${droneserver}" = "ALL PRIVILEGES";
        };
      }
    ];
  };

  sops.secrets.drone = {
    sopsFile = ../.secrets/drone.yaml;
    # owner = droneserver;
  };

  systemd.services.drone-server = {
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      EnvironmentFile = [
        config.sops.secrets.drone.path
      ];
      Environment = [
        "DRONE_DATABASE_DATASOURCE=postgres:///droneserver?host=/run/postgresql"
        "DRONE_DATABASE_DRIVER=postgres"
        "DRONE_SERVER_PORT=:3030"
        "DRONE_USER_CREATE=username:viperML,admin:true"

        "DRONE_GITEA_SERVER=https://git.ayats.org"
        "DRONE_SERVER_HOST=drone.ayats.org"
        "DRONE_SERVER_PROTO=https"
      ];
      ExecStart = "${pkgs.drone}/bin/drone-server";
      User = droneserver;
      Group = droneserver;
    };
  };

  ### Docker runner

  users.users.drone-runner-docker = {
    isSystemUser = true;
    group = "drone-runner-docker";
  };
  users.groups.drone-runner-docker = {};

  users.groups.docker.members = ["drone-runner-docker"];
  systemd.services.drone-runner-docker = {
    enable = true;
    wantedBy = ["multi-user.target"];
    ### MANUALLY RESTART SERVICE IF CHANGED
    restartIfChanged = false;
    serviceConfig = {
      Environment = [
        "DRONE_RPC_PROTO=http"
        "DRONE_RPC_HOST=localhost:3030"
        "DRONE_RUNNER_CAPACITY=2"
        "DRONE_RUNNER_NAME=drone-runner-docker"
      ];
      EnvironmentFile = [
        config.sops.secrets.drone.path
      ];
      ExecStart = "${pkgs.drone-runner-docker}/bin/drone-runner-docker";
      User = "drone-runner-docker";
      Group = "drone-runner-docker";
    };
  };

  ### Exec runner
  users.users.drone-runner-exec = {
    isSystemUser = true;
    group = "drone-runner-exec";
    home = "/var/drone-runner/exec";
  };
  users.groups.drone-runner-exec = {};

  nix.allowedUsers = ["drone-runner-exec"];
  systemd.services.drone-runner-exec = {
    enable = true;
    wantedBy = ["multi-user.target"];
    # Updates would restart the service
    # Schedule accordingly
    restartIfChanged = true;
    confinement.enable = true;
    confinement.packages = [
      pkgs.git
      pkgs.gnutar
      pkgs.bash
      config.nix.package
      pkgs.gzip
    ];
    path = [
      pkgs.git
      pkgs.gnutar
      pkgs.bash
      config.nix.package
      pkgs.gzip
    ];
    serviceConfig = {
      Environment = [
        "DRONE_RPC_PROTO=http"
        "DRONE_RPC_HOST=127.0.0.1:3030"
        "DRONE_RUNNER_CAPACITY=2"
        "DRONE_RUNNER_NAME=drone-runner-exec"
        "NIX_REMOTE=daemon"
        "PAGER=cat"
        "DRONE_DEBUG=true"
      ];
      BindPaths = [
        "/nix/var/nix/daemon-socket/socket"
        "/run/nscd/socket"
        # "/var/lib/drone"
      ];
      BindReadOnlyPaths = [
        "/etc/passwd:/etc/passwd"
        "/etc/group:/etc/group"
        "/nix/var/nix/profiles/system/etc/nix:/etc/nix"
        "${config.environment.etc."ssl/certs/ca-certificates.crt".source}:/etc/ssl/certs/ca-certificates.crt"
        "${config.environment.etc."ssh/ssh_known_hosts".source}:/etc/ssh/ssh_known_hosts"
        "${builtins.toFile "ssh_config" ''
          Host git.ayats.org
          ForwardAgent yes
        ''}:/etc/ssh/ssh_config"
        "/etc/machine-id"
        "/etc/resolv.conf"
        "/nix/"
        "/usr"
      ];
      EnvironmentFile = [
        config.sops.secrets.drone.path
      ];
      ExecStart = "${pkgs.drone-runner-exec}/bin/drone-runner-exec";
      User = "drone-runner-exec";
      Group = "drone-runner-exec";
    };
  };
}
