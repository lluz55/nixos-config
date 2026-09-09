{ config, lib, pkgs, ... }:
let
  cfg = config.services.dsh;
  dsh-pkg = pkgs.callPackage ./package.nix { };
in
{
  options.services.dsh = {
    enable = lib.mkEnableOption "DeepSeek Harness (dsh) web profile daemon";

    package = lib.mkOption {
      type = lib.types.package;
      default = dsh-pkg;
      description = "Package providing dsh.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 3080;
      description = ''
        Listen port for `dsh --profile web`. The upstream web app refuses
        `--host 0.0.0.0` on purpose (would expose remote code execution to
        the network), so this service always binds 127.0.0.1 — reach it
        remotely via SSH port-forward, Tailscale/Netbird, or mosh, all
        already available on this host.
      '';
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "lluz";
      description = "User account under which dsh runs (owns $HOME/.dsh).";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.dsh = {
      description = "DeepSeek Harness (dsh) web profile";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];

      path = with pkgs; [ nodejs_22 bash coreutils git ripgrep ];

      environment = {
        HOME = "/home/${cfg.user}";
      };

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        WorkingDirectory = "/home/${cfg.user}";
        ExecStart = "${lib.getExe cfg.package} web --port ${toString cfg.port} --no-open";
        Restart = "on-failure";
        RestartSec = "5s";
      };
    };
  };
}
