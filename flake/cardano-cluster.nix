{
  flake.cardano-parts.cluster = {
    infra.aws.domain = "home.network";
    infra.generic = {
      abortOnMissingIpModule = false;
      warnOnMissingIpModule = false;
    };
    groups.default.meta.environmentName = "mainnet";
  };
}
