{ lib, config, masterUser, ... }:
with lib;
{
  options.twingate.enable = mkOption {
    type = types.bool;
    default = false;
    description = mdDoc "Enable twingate connector";
  };

  config = mkIf (config.twingate.enable) {
    virtualisation.oci-containers.containers."twingate" = {
      image = "twingate/connector:1.85";
      environment = {
        TWINGATE_LABEL_HOSTNAME = "`hostname`";
      };
      extraOptions = [
        "--dns=8.8.8.8,1.1.1.1"
        "--network=host"
        "--env-file=${config.sops.secrets."twingate.env".path}"
      ];
    };
  };
}
