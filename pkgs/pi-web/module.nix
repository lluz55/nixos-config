{ config, lib, pkgs, ... }:
let
  cfg = config.services.pi-web;

  # Sincroniza o catálogo de modelos do 9router para dentro de
  # ~/.pi/agent/models.json (o Pi Coding Agent trata o 9router como provider
  # OpenAI-compatible custom: nada nele vem de um catálogo embutido, então
  # `models` fica obsoleto sempre que o upstream muda). O script reescreve
  # só providers."9router".models e preserva nomes já ajustados à mão.
  modelSyncScript = ../../scripts/sync-pi-9router-models.sh;
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

    houndPackage = lib.mkOption {
      type = lib.types.package;
      default = pkgs.callPackage ../hound-mcp/package.nix { };
      defaultText = lib.literalExpression "pkgs.callPackage ../hound-mcp/package.nix { }";
      description = "Hound MCP wrapper exposed to Pi Coding Agent sessions.";
    };

    modelSync = {
      enable = lib.mkEnableOption ''
        timer periódico que sincroniza o catálogo de modelos do 9router
        para dentro de ~/.pi/agent/models.json
      '';

      baseURL = lib.mkOption {
        type = lib.types.str;
        default = "http://localhost:20128/v1";
        description = "Endpoint OpenAI-compatible consultado em GET /v1/models.";
      };

      interval = lib.mkOption {
        type = lib.types.str;
        default = "daily";
        example = "*-*-* 04:00:00";
        description = ''
          `OnCalendar` do timer. O pi recarrega `models.json` sozinho ao
          abrir `/model`, então o sync nunca reinicia nada.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.pi-web-sessiond = {
      description = "PI WEB session daemon (persistent Pi Coding Agent sessions)";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];

      # Coding-agent sessions inherit the daemon environment. The Hound Pi
      # extension locates the executable by running `which hound`, so both the
      # wrapper and `which` itself must be available in this isolated PATH.
      path = with pkgs; [ nodejs git ripgrep bash coreutils which cfg.houndPackage ];

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

    # O sync roda como o próprio usuário (dono de ~/.pi) e não reinicia nada:
    # o pi recarrega models.json sozinho ao abrir /model.
    systemd.services.pi-model-sync = lib.mkIf cfg.modelSync.enable {
      description = "Sync 9router model catalog into Pi Coding Agent's models.json";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];

      path = with pkgs; [ nodejs bash coreutils ];

      environment = {
        HOME = "/home/${cfg.user}";
        NINEROUTER_BASE_URL = cfg.modelSync.baseURL;
      };

      serviceConfig = {
        Type = "oneshot";
        User = cfg.user;
        WorkingDirectory = "/home/${cfg.user}";
        ExecStart = "${pkgs.bash}/bin/bash ${modelSyncScript} --quiet";
      };
    };

    systemd.timers.pi-model-sync = lib.mkIf cfg.modelSync.enable {
      description = "Periodic 9router model catalog sync for Pi Coding Agent";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = cfg.modelSync.interval;
        Persistent = true;
        RandomizedDelaySec = "5m";
      };
    };
  };
}
