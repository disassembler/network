{
  darwin = {
    ohrid = {
      hostName = "10.40.33.170";
      maxJobs = 2;
      sshUser = "sam";
      sshKey = "/etc/nixos/keys/build";
      system = "x86_64-darwin";
    };
    macvm = {
      hostName = "10.40.33.160";
      maxJobs = 1;
      sshUser = "sam";
      sshKey = "/etc/nixos/keys/build";
      system = "x86_64-darwin";
    };
  };
  linux = {
    optina = {
      hostName = "10.40.33.20";
      maxJobs = 4;
      sshUser = "root";
      sshKey = "/etc/nixos/keys/build";
      system = "x86_64-linux";
    };
  };
}
