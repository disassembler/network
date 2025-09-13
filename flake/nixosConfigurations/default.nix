{
  inputs,
  config,
  ...
}: {
  flake.nixosConfigurations = (inputs.colmena.lib.makeHive config.flake.colmena).nodes;
}
