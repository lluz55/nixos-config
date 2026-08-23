{ config, lib, pkgs, ... }:
let
  cfg = config.services."9router";
  nine-router-pkg = pkgs.callPackage ./package.nix { inherit (pkgs) nodejs; };
in
{
  options.services."9router" = {
    enable = lib.mkEnableOption "9router AI proxy gateway daemon";

    package = lib.mkOption {
      type = lib.types.package;
      default = nine-router-pkg;
      description = "Package or wrapper providing 9router.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 20128;
      description = "Port to bind 9router.";
    };

    host = lib.mkOption {
      type = lib.types.str;
      default = "0.0.0.0";
      description = "Host to bind 9router.";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "lluz";
      description = "User account under which 9router runs.";
    };

    headroom = {
      enable = lib.mkEnableOption "Headroom context optimization proxy alongside 9router";

      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.callPackage ./../headroom/package.nix { };
        description = "Package providing Headroom.";
      };

      port = lib.mkOption {
        type = lib.types.port;
        default = 8787;
        description = "Port to bind Headroom proxy.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services."9router" = {
      description = "9Router AI Proxy Gateway";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];

      path = with pkgs; [ nodejs bash coreutils ];

      environment = {
        HOME = "/home/${cfg.user}";
      };

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        WorkingDirectory = "/home/${cfg.user}";
        ExecStart = "${lib.getExe cfg.package} --port ${toString cfg.port} --host ${cfg.host} --no-browser --log --skip-update";
        Restart = "always";
        RestartSec = "5s";
      };
    };

    systemd.services."headroom" = lib.mkIf cfg.headroom.enable {
      description = "Headroom Context Optimization Proxy";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];

      path = with pkgs; [ git coreutils bash uv ];

      environment = {
        HOME = "/home/${cfg.user}";
      };

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        WorkingDirectory = "/home/${cfg.user}";
        ExecStart = "${lib.getExe cfg.headroom.package} proxy --port ${toString cfg.headroom.port}";
        Restart = "on-failure";
        RestartSec = "5s";
      };
    };
  };
}
