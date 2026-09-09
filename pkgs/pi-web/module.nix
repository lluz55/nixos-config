{ config, lib, pkgs, ... }:
let
  cfg = config.services.pi-web;
in
{
  options.services.pi-web = {
    enable = lib.mkEnableOption "PI WEB - web UI for persistent Pi Coding Agent sessions";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.callPackage ./package.nix { };
      defaultText = lib.literalExpression "pkgs.callPackage ./package.nix { }";
      description = "pi-web package providing pi-web, pi-web-server and pi-web-sessiond.";
    };

    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Host/address to bind the PI WEB web/API server (PI_WEB_HOST).";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 8504;
      description = "Port to bind the PI WEB web/API server (PI_WEB_PORT).";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "lluz";
      description = "User account under which PI WEB (session daemon + web/API) runs.";
    };

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/home/${cfg.user}/.pi-web";
      defaultText = lib.literalExpression ''"/home/''${cfg.user}/.pi-web"'';
      description = "PI WEB managed data directory (PI_WEB_DATA_DIR), shared between sessiond and web/API.";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.pi-web-sessiond = {
      description = "PI WEB session daemon (persistent Pi Coding Agent sessions)";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];

      path = with pkgs; [ nodejs git ripgrep bash coreutils ];

      environment = {
        HOME = "/home/${cfg.user}";
        PI_WEB_DATA_DIR = cfg.dataDir;
      };

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        WorkingDirectory = "/home/${cfg.user}";
        ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p ${cfg.dataDir}";
        ExecStart = "${cfg.package}/bin/pi-web-sessiond";
        Restart = "always";
        RestartSec = "5s";
      };
    };

    systemd.services.pi-web-server = {
      description = "PI WEB web/API server";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" "pi-web-sessiond.service" ];
      wants = [ "network-online.target" ];
      requires = [ "pi-web-sessiond.service" ];

      path = with pkgs; [ nodejs git ripgrep bash coreutils ];

      environment = {
        HOME = "/home/${cfg.user}";
        PI_WEB_DATA_DIR = cfg.dataDir;
        PI_WEB_HOST = cfg.host;
        PI_WEB_PORT = toString cfg.port;
      };

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        WorkingDirectory = "/home/${cfg.user}";
        ExecStart = "${cfg.package}/bin/pi-web-server";
        Restart = "always";
        RestartSec = "5s";
      };
    };
  };
}
