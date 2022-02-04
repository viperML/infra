{ config, pkgs, ... }:
{
  users.mutableUsers = false;
  users.users.root.passwordFile = config.sops.secrets."password/root".path;
  users.users.admin = {
    name = "admin";
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIBZkBer8ozZ/6u7AQ1FHXiF1MbetEUKZoV5xN5YkhMo ayatsfer@gmail.com
"
    ];
  };
  security.sudo.wheelNeedsPassword = false;
  nix.trustedUsers = [ "@wheel" ]; # https://github.com/serokell/deploy-rs/issues/25
  services.openssh = { enable = true; };

  sops = {
    secrets."password/root" = {
      sopsFile = ../.secrets/passwords.yaml;
      neededForUsers = true;
    };
    secrets."password/admin" = {
      sopsFile = ../.secrets/passwords.yaml;
      neededForUsers = true;
    };
  };

  users.groups.docker.members = config.users.groups.wheel.members;
}
