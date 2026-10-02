{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.omniroute;
in
{
  options.services.omniroute = {
    enable = lib.mkEnableOption "OmniRoute AI gateway";

    package = lib.mkOption {
      type = lib.types.package;
      description = "Package providing the omniroute executable.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 20129;
      description = "Dashboard and API port.";
    };

    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Address on which OmniRoute listens.";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "lluz";
      description = "User account under which OmniRoute runs.";
    };

    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/home/${cfg.user}/.omniroute";
      description = "Persistent OmniRoute state directory.";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0700 ${cfg.user} users -"
    ];

    systemd.services.omniroute = {
      description = "OmniRoute AI Gateway";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];

      environment = {
        HOME = "/home/${cfg.user}";
        DATA_DIR = cfg.dataDir;
        PORT = toString cfg.port;
        OMNIROUTE_SERVER_HOST = cfg.host;
        OMNIROUTE_NO_UPDATE_NOTIFIER = "1";
      };

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        WorkingDirectory = cfg.dataDir;
        ExecStart = "${lib.getExe cfg.package} serve --port ${toString cfg.port} --no-open --log";
        Restart = "on-failure";
        RestartSec = "5s";
      };
    };
  };
}
