{pkgs, ...}: {
  fileSystems."/tmp/plex-transcode" = {
    device = "tmpfs";
    fsType = "tmpfs";
    options = ["size=8G" "mode=0755"];
  };

  # Post-deploy: set in Plex web UI → Settings → Troubleshooting:
  #   Transcoder temporary directory       = /tmp/plex-transcode
  #   Transcoder default download directory = /tmp/plex-transcode
  services.plex.enable = true;

  systemd.services.plex = {
    after = [ "data-media.mount" "tmp-plex\\x2dtranscode.mount" ];
    requires = [ "data-media.mount" "tmp-plex\\x2dtranscode.mount" ];
  };

  services.samba = {
    enable = true;
    settings = {
      global = {
        "guest account" = "nobody";
        "map to guest" = "bad user";
      };
      meganbackup = {
        path = "/data/backups/other/megan";
        "valid users" = "sam megan";
        writable = "yes";
        comment = "Megan's Backup";
      };
      musicdrive = {
        path = "/data/pvr/music";
        "valid users" = "sam megan";
        writable = "yes";
        comment = "music share";
      };
    };
  };

  services.printing = {
    enable = true;
    drivers = [pkgs.hplip];
    defaultShared = true;
    browsing = true;
    listenAddresses = ["*:631"];
    allowFrom = ["all"];
    extraConf = ''
      ServerAlias *
    '';
  };

  services.mopidy.enable = false;

  services.mpd = {
    enable = false;
    settings.music_directory = "/data/pvr/music";
    credentials = [
      {
        permissions = ["admin" "read" "add" "control"];
      }
      {
        permissions = ["read" "add" "control"];
      }
    ];
  };
}
