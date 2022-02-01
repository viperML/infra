{ config, pkgs, inputs, ... }:
let
  minecraft-dir = "/var/lib/minecraft";
in
{
  virtualisation.oci-containers.containers.minecraft = {
    image = "viperml/skyfactory-4";
    imageFile = inputs.docker-skyfactory4.packages.${pkgs.system}.docker-image;
    ports = [ "25565:25565" ];
    volumes = [
      "skyfactory-4:/var/lib/skyfactory4:rw"
      "${minecraft-dir}/skyfactory-4/world:/var/lib/skyfactory4/world:rw"
    ];
  };

  fileSystems."${minecraft-dir}" = {
    device = "zroot/data/minecraft";
    fsType = "zfs";
  };

  networking.firewall.allowedTCPPorts = [ 25565 ];
}
