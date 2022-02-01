{ config, pkgs, modulesPath, ... }:
let
  my-net-interface = "enp1s0";
  my-disk = "/dev/sda";
in
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  networking = {
    hostId = builtins.substring 0 8 (builtins.hashString "md5" config.networking.hostName);
    useNetworkd = true;
    useDHCP = false;
    interfaces.${my-net-interface} = {
      useDHCP = true;
    };
  };

  fileSystems = {
    "/boot" = {
      device = "${my-disk}2";
      fsType = "ext4";
    };

    "/" = {
      device = "zroot/rootfs";
      fsType = "zfs";
    };

    "/nix" = {
      device = "zroot/nix";
      fsType = "zfs";
    };

    "/secrets" = {
      device = "zroot/secrets";
      fsType = "zfs";
      neededForBoot = true;
    };

    "/var/lib/postgres" = {
      device = "zroot/data/postgres";
      fsType = "zfs";
    };

    "/var/lib/acme" = {
      device = "zroot/data/acme";
      fsType = "zfs";
    };

    "${config.services.gitea.stateDir}" = {
      device = "zroot/data/gitea";
      fsType = "zfs";
    };
  };

  services.zfs.autoScrub = {
    enable = true;
    pools = [ "zroot" ];
    interval = "weekly";
  };

  services.sanoid = {
    enable = true;
    templates = {
      "normal" = {
        "frequently" = 0;
        "hourly" = 1;
        "daily" = 1;
        "monthly" = 4;
        "yearly" = 0;
        "autosnap" = true;
        "autoprune" = true;
      };
    };
    datasets = {
      "zroot/secrets" = {
        useTemplate = [ "normal" ];
      };
      "zroot/data/postgres" = {
        useTemplate = [ "normal" ];
      };
      "zroot/data/gitea" = {
        useTemplate = [ "normal" ];
      };
    };
  };

  swapDevices = [
    { device = "/dev/zvol/zroot/swap"; }
  ];

  boot = {
    initrd.availableKernelModules = [ "ahci" "xhci_pci" "virtio_pci" "sd_mod" "sr_mod" ];
    loader.grub = {
      enable = true;
      device = my-disk;
      zfsSupport = true;
      configurationLimit = 10;
    };
  };
}
