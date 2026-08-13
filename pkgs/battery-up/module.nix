{ config, lib, pkgs, ... }:
let
  cfg = config.services.battery-up;
in
{
  options.services.battery-up = {
    enable = lib.mkEnableOption "battery-up background battery-only timer";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.callPackage ./package.nix { };
      defaultText = lib.literalExpression "pkgs.callPackage ./package.nix { }";
      description = "battery-up package to run (prebuilt release binary).";
    };

    interval = lib.mkOption {
      type = lib.types.ints.positive;
      default = 1;
      description = "Polling interval in seconds.";
    };

    stateFile = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/battery-up/state";
      description = "File where the daemon stores the accumulated time.";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.battery-up = {
      description = "Track notebook time running only on battery";
      wantedBy = [ "multi-user.target" ];
      after = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${lib.getExe cfg.package} daemon --interval ${toString cfg.interval} --state-file ${cfg.stateFile}";
        Restart = "always";
        RestartSec = "5s";
        StateDirectory = "battery-up";
      };
    };
  };
}
