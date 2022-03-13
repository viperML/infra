{
  config,
  pkgs,
  inputs,
  lib,
  ...
}: {
  time.timeZone = "UTC";
  system.stateVersion = "21.11";
  system.configurationRevision = inputs.self.rev or null;

  environment.systemPackages = with pkgs; [
    fish
    htop
  ];
}
