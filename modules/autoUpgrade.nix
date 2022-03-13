{
  config,
  pkgs,
  ...
}: {
  system.autoUpgrade = {
    enable = true;
    flake = "github:viperML/infra";
    allowReboot = true;
  };
}
