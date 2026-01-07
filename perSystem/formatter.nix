{
  perSystem = {
    config,
    pkgs,
    ...
  }: {
    # This replaces the need for an external treefmt.toml
    treefmt = {
      # 1. Point to the root of your repo
      projectRootFile = "flake.nix";

      # 2. Enable the programs you want (no store paths needed!)
      programs.alejandra.enable = true;

      # 3. Add your global settings/excludes
      settings.global.excludes = [
        "*.lock"
        "*.patch"
        "package-lock.json"
        "go.mod"
        "go.sum"
        ".gitattributes"
        ".gitignore"
        ".gitmodules"
        "LICENSE"
      ];

      # 4. Optional: Custom overrides for specific formatters
      settings.formatter.alejandra = {
        includes = ["**/*.nix"];
      };
    };

    # This makes 'nix fmt' work automatically
    formatter = config.treefmt.build.wrapper;
  };
}
