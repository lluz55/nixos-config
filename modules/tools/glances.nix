{ config, lib, pkgs, ... }:
with lib; {
  config = mkIf (config.glances.enable) {
    systemd.services.start_glances = {
      wantedBy = [ "multi-user.target" ];
      script = ''${pkgs.glances}/bin/glances -w'';
    };

  };
}
