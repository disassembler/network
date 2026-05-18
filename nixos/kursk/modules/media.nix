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
    musicDirectory = "/data/pvr/music";
    credentials = [
      {
        permissions = ["admin" "read" "add" "control"];
      }
      {
        permissions = ["read" "add" "control"];
      }
    ];
    extraConfig = ''
      log_level "verbose"
      restore_paused "no"
      metadata_to_use "artist,album,title,track,name,genre,date,composer,performer,disc,comment"
      bind_to_address "10.40.33.70"
      input {
      plugin "curl"
      }
      audio_output {
      type        "shout"
      encoding    "ogg"
      name        "Icecast stream"
      host        "prophet.samleathers.com"
      port        "8000"
      mount       "/mpd.ogg"
      public      "yes"
      bitrate     "192"
      format      "44100:16:1"
      user        "mpd"
      }
      audio_output {
      type "alsa"
      name "fake out"
      driver "null"
      }
    '';
  };
}
