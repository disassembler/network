{
  lib,
  config,
  pkgs,
  ...
}: {
  services.home-assistant = {
    enable = true;
    package =
      (pkgs.home-assistant.override {
        extraComponents = ["sense" "roku" "homekit"];
      })
      .overrideAttrs (oldAttrs: {doInstallCheck = false;});
    config = {
      default_config = {};
      met = {};
      sense = {};
      roku = {};
      homekit = {};
      http = {
        server_host = "10.40.33.70";
        server_port = 8123;
      };
    };
  };

  # Expose the hass CLI in the system PATH
  environment.systemPackages = [config.services.home-assistant.package];
}
