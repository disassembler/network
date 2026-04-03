{
  inputs,
  lib,
  pkgs,
  ...
}: let
  poolName = "zpool";

  # Single source of truth for ZFS datasets.
  # Referenced by both the disko config below and the activation script,
  # so adding a dataset here is all that's needed — no manual zfs-create on
  # future deploys to an already-running system.
  datasets = {
    "nixos/root" = {
      type = "zfs_fs";
      mountpoint = "/";
      options.mountpoint = "legacy";
    };
    "nixos/nix" = {
      type = "zfs_fs";
      mountpoint = "/nix";
      options.mountpoint = "legacy";
    };
    "nixos/var" = {
      type = "zfs_fs";
      mountpoint = "/var";
      options.mountpoint = "legacy";
    };
    "nixos/var/prometheus" = {
      type = "zfs_fs";
      mountpoint = "/var/lib/prometheus";
      options = {
        mountpoint = "legacy";
        "com.sun:auto-snapshot" = "false";
        atime = "off";
        recordsize = "1M";
        compression = "lz4";
      };
    };
    # Regular PostgreSQL — tuned for OLTP (8K matches postgres page size)
    "nixos/var/postgresql" = {
      type = "zfs_fs";
      mountpoint = "/var/lib/postgresql";
      options = {
        mountpoint = "legacy";
        "com.sun:auto-snapshot" = "true";
        atime = "off";
        recordsize = "8K";
        logbias = "throughput";
        compression = "lz4";
      };
    };
    # Isolated PostgreSQL for AI workloads (ParadeDB + pgvector).
    # Large record size suits sequential vector scans; snapshots disabled
    # since embeddings can be regenerated.
    "nixos/var/postgresql-ai" = {
      type = "zfs_fs";
      mountpoint = "/var/lib/postgresql-ai";
      options = {
        mountpoint = "legacy";
        "com.sun:auto-snapshot" = "false";
        atime = "off";
        recordsize = "128K";
        logbias = "throughput";
        compression = "lz4";
      };
    };
    "userdata/sam" = {
      type = "zfs_fs";
      mountpoint = "/home/sam";
      options.mountpoint = "legacy";
    };
    "userdata/root" = {
      type = "zfs_fs";
      mountpoint = "/root";
      options.mountpoint = "legacy";
    };
    "storage" = {
      type = "zfs_fs";
      mountpoint = "/data/storage";
      options.mountpoint = "legacy";
    };
    "storage/windows" = {
      type = "zfs_fs";
      mountpoint = "/data/storage/windows";
      options = {
        mountpoint = "legacy";
        snapdir = "visible";
        "com.sun:auto-snapshot" = "true";
      };
    };
  };

  # Generate a shell snippet that creates a single dataset if it doesn't exist.
  # mapAttrsToList sorts keys alphabetically, which conveniently means parents
  # (e.g. nixos/var) are always created before children (nixos/var/postgresql).
  mkCreateDataset = name: ds:
    let
      opts = lib.concatStringsSep " " (
        lib.mapAttrsToList (k: v: "-o ${lib.escapeShellArg "${k}=${v}"}") (ds.options or {})
      );
    in ''
      if ! ${pkgs.zfs}/bin/zfs list ${lib.escapeShellArg "${poolName}/${name}"} > /dev/null 2>&1; then
        echo "zfs-datasets: creating ${poolName}/${name}"
        ${pkgs.zfs}/bin/zfs create ${opts} ${lib.escapeShellArg "${poolName}/${name}"}
      fi
    '';
in {
  imports = [inputs.disko.nixosModules.disko];

  # On every nixos-rebuild switch / colmena apply, ensure all declared datasets
  # exist before systemd attempts to start the generated mount units.
  system.activationScripts.zfs-datasets = {
    deps = ["specialfs"];
    text = lib.concatStrings (lib.mapAttrsToList mkCreateDataset datasets);
  };

  disko.devices = {
    disk.main = {
      device = "/dev/nvme0n1";
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            size = "1G";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
            };
          };
          swap = {
            size = "8G";
            content = {
              type = "swap";
              discardPolicy = "both";
              resumeDevice = true;
            };
          };
          zfs = {
            size = "100%";
            content = {
              type = "zfs";
              pool = poolName;
            };
          };
        };
      };
    };
    zpool.${poolName} = {
      type = "zpool";
      rootFsOptions = {
        compression = "lz4";
        mountpoint = "none";
      };
      inherit datasets;
    };
  };
}
