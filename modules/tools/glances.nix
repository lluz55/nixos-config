{ config, lib, pkgs, ... }:
with lib; {
  options.glances.enable = mkOption {
    type = types.bool;
    default = false;
    description = mdDoc "Enable Glances and creating a startup service for it";
  };

  config = mkIf (config.glances.enable) {
    systemd.services.start_glances = {
      wantedBy = [ "multi-user.target" ];
      script = ''${pkgs.glances}/bin/glances -w'';
    };

  };
}
