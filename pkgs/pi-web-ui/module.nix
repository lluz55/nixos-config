{ config, lib, pkgs, ... }:
let
  cfg = config.services.pi-web-ui;
  home = "/home/${cfg.user}";
  stateDir = "${home}/.pi-web-ui";
  runtimePath = [
    pkgs.nodejs_22
    pkgs.git
    pkgs.ripgrep
    pkgs.bash
    pkgs.coreutils
    pkgs.which
    pkgs.curl
  ] ++ cfg.extraPackages;
in
{
  options.services.pi-web-ui = {
    enable = lib.mkEnableOption "valtterimelkko/pi-web-ui side by side with PI WEB";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.callPackage ./package.nix { };
      defaultText = lib.literalExpression "pkgs.callPackage ./package.nix { }";
      description = "Package providing the pi-web-ui executable.";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "lluz";
      description = "User account that owns Pi Web UI and its agent sessions.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 8585;
      description = "Loopback HTTP port for Pi Web UI.";
    };

    environmentFile = lib.mkOption {
      type = lib.types.path;
      description = "Environment file containing JWT_SECRET, CSRF_SECRET and AUTH_PASSWORD.";
    };

    allowedOrigins = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "https://example.trycloudflare.com" ];
      description = "Exact browser origins accepted by CORS and WebSocket checks.";
    };

    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = "Additional agent runtime executables exposed on the service PATH.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.allowedOrigins != [ ];
        message = "services.pi-web-ui.allowedOrigins must contain every browser origin used to access the UI.";
      }
    ];

    systemd.services.pi-web-ui = {
      description = "Pi Web UI (multi-runtime coding-agent interface)";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];

      path = runtimePath;

      environment = {
        HOME = home;
        NODE_ENV = "production";
        PORT = toString cfg.port;
        ALLOWED_ORIGINS = lib.concatStringsSep "," cfg.allowedOrigins;
        PI_AGENT_DIR = "${home}/.pi/agent";
        OPENCODE_ENABLED = "false";
        ANTIGRAVITY_ENABLED = "false";
        COMMAND_CODE_ENABLED = "false";
        CLAUDE_PROFILES_ENABLED = "false";
        CLAUDE_CHANNEL_ENABLED = "false";
        INTERNAL_API_ENABLED = "true";
        INTERNAL_API_SOCKET_PATH = "${stateDir}/internal-api.sock";
        INTERNAL_API_TOKEN_PATH = "${stateDir}/internal-api-token";
      };

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        WorkingDirectory = home;
        EnvironmentFile = cfg.environmentFile;
        ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p ${stateDir}";
        ExecStart = "${cfg.package}/bin/pi-web-ui";
        Restart = "on-failure";
        RestartSec = "5s";
        UMask = "0077";
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = false;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        RestrictSUIDSGID = true;
        LockPersonality = true;
        RestrictRealtime = true;
        RestrictAddressFamilies = [ "AF_INET" "AF_INET6" "AF_UNIX" ];
      };
    };
  };
}
