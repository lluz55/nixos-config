{ config, lib, pkgs, ... }:

let
  cfg = config.services.cota-dashboard;
  pkg = pkgs.callPackage ./package.nix { };
in
{
  options.services.cota-dashboard = {
    enable = lib.mkEnableOption "Cota — visual quota dashboard for 9Router";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkg;
      description = "Package providing the dashboard (HTML + Node proxy).";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 20129;
      description = "Loopback port the dashboard listens on (must be reachable by dl_conn).";
    };

    ninerouter = lib.mkOption {
      type = lib.types.str;
      default = "http://127.0.0.1:20128";
      description = "URL of the 9Router instance the dashboard proxies API calls to.";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "lluz";
      description = "User account under which the dashboard runs.";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.cota-dashboard = {
      description = "Cota — visual quota dashboard for 9Router";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" "9router.service" ];
      wants = [ "network-online.target" ];

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        WorkingDirectory = "/home/${cfg.user}";
        ExecStart = "${lib.getExe cfg.package}/lib/cota-dashboard/server.js";
        Environment = [
          "PORT=${toString cfg.port}"
          "HOST=127.0.0.1"
          "NINEROUTER=${cfg.ninerouter}"
        ];
        Restart = "always";
        RestartSec = "3s";
      };
    };
  };
}
