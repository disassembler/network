{
  inputs,
  lib,
  pkgs,
  ...
}: let
  poolName = "zpool";
  mediaPool = "media";

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

  # 4x Samsung 870 QVO 8TB SATA SSDs
  mediaDisks = {
    sata1 = "/dev/disk/by-id/ata-Samsung_SSD_870_QVO_8TB_S5VUNJ0W703456T";
    sata2 = "/dev/disk/by-id/ata-Samsung_SSD_870_QVO_8TB_S5VUNJ0W709468T";
    sata3 = "/dev/disk/by-id/ata-Samsung_SSD_870_QVO_8TB_S5VUNJ0W705710B";
    sata4 = "/dev/disk/by-id/ata-Samsung_SSD_870_QVO_8TB_S5VUNJ0W202766Z";
  };

  mediaDatasets = {
    "media" = {
      type = "zfs_fs";
      mountpoint = "/data/media";
      options = {
        mountpoint = "legacy";
        recordsize = "1M";
        compression = "zstd";
        atime = "off";
        "com.sun:auto-snapshot" = "false";
      };
    };
    "backup" = {
      type = "zfs_fs";
      mountpoint = "/data/backup";
      options = {
        mountpoint = "legacy";
        recordsize = "1M";
        compression = "zstd";
        atime = "off";
        "com.sun:auto-snapshot" = "true";
      };
    };
    "downloads" = {
      type = "zfs_fs";
      mountpoint = "/data/downloads";
      options = {
        mountpoint = "legacy";
        recordsize = "1M";
        compression = "zstd";
        atime = "off";
        "com.sun:auto-snapshot" = "false";
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

  mkCreateMediaDataset = name: ds:
    let
      opts = lib.concatStringsSep " " (
        lib.mapAttrsToList (k: v: "-o ${lib.escapeShellArg "${k}=${v}"}") (ds.options or {})
      );
    in ''
      if ! ${pkgs.zfs}/bin/zfs list ${lib.escapeShellArg "${mediaPool}/${name}"} > /dev/null 2>&1; then
        echo "zfs-datasets: creating ${mediaPool}/${name}"
        ${pkgs.zfs}/bin/zfs create ${opts} ${lib.escapeShellArg "${mediaPool}/${name}"}
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

  system.activationScripts.zfs-media-datasets = {
    deps = ["specialfs"];
    text = ''
      if ${pkgs.zfs}/bin/zpool list ${lib.escapeShellArg mediaPool} > /dev/null 2>&1; then
        ${lib.concatStrings (lib.mapAttrsToList mkCreateMediaDataset mediaDatasets)}
      fi
    '';
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
    disk.sata1 = {
      device = mediaDisks.sata1;
      type = "disk";
      content = {
        type = "gpt";
        partitions.zfs = {
          size = "100%";
          content = {type = "zfs"; pool = mediaPool;};
        };
      };
    };
    disk.sata2 = {
      device = mediaDisks.sata2;
      type = "disk";
      content = {
        type = "gpt";
        partitions.zfs = {
          size = "100%";
          content = {type = "zfs"; pool = mediaPool;};
        };
      };
    };
    disk.sata3 = {
      device = mediaDisks.sata3;
      type = "disk";
      content = {
        type = "gpt";
        partitions.zfs = {
          size = "100%";
          content = {type = "zfs"; pool = mediaPool;};
        };
      };
    };
    disk.sata4 = {
      device = mediaDisks.sata4;
      type = "disk";
      content = {
        type = "gpt";
        partitions.zfs = {
          size = "100%";
          content = {type = "zfs"; pool = mediaPool;};
        };
      };
    };
    zpool.${mediaPool} = {
      type = "zpool";
      mode = "raidz1";
      options = {
        ashift = "12";
        autotrim = "on";
      };
      rootFsOptions = {
        compression = "zstd";
        atime = "off";
        xattr = "sa";
        dnodesize = "auto";
        mountpoint = "none";
      };
      datasets = mediaDatasets;
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
