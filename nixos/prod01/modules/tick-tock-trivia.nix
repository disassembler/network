{inputs, ...}: {
  imports = [inputs.tick-tock-trivia.nixosModules.default];

  services.tick-tock-trivia = {
    enable = true;
    stateDirectory = "tick-tock-trivia";
    quizzesDir = "/var/lib/tick-tock-trivia/quizzes";
    listenAddress = "127.0.0.1";
    port = 8080;
    openFirewall = false;
  };

  # Deploy banks independently of the writable player and score files.
  systemd.tmpfiles.rules = [
    "L+ /var/lib/tick-tock-trivia/quizzes - - - - ${../../../quizzes}"
  ];

  # Remount the read-only quiz path when a deployment changes its target.
  systemd.services.tick-tock-trivia = {
    after = ["systemd-tmpfiles-resetup.service"];
    restartTriggers = [../../../quizzes];
  };

  services.nginx.virtualHosts."ticktock.disasm.us" = {
    enableACME = true;
    forceSSL = true;
    locations."/".proxyPass = "http://127.0.0.1:8080";
  };
}
