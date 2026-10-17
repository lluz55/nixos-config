{ config, lib, pkgs, ... }:
let
  cfg = config.services.agegr-pi-web;
  home = "/home/${cfg.user}";
in
{
  options.services.agegr-pi-web = {
    enable = lib.mkEnableOption "@agegr/pi-web — local web UI for the pi coding agent";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.callPackage ./package.nix { };
      defaultText = lib.literalExpression "pkgs.callPackage ./package.nix { }";
      description = "Package providing the `pi-web` binary (wraps @agegr/pi-web).";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "lluz";
      description = "User account under which @agegr/pi-web runs. It reads `~/.pi/agent` from this user's HOME.";
    };

    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Bind hostname (PI_WEB_HOSTNAME). The dl_conn reverse proxy connects via loopback, so 127.0.0.1 is enough.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 30141;
      description = "Loopback HTTP port (default of @agegr/pi-web).";
    };

    # PI_WEB_ALLOWED_HOSTS controla o fence de Host/CORS do upstream. Sem
    # ele configurado, requisições cujo Host não bate em `host`/`hostname` nem
    # 127.0.0.1/<this-host> são recusadas. O dl_conn proxia com o
    # hostname trycloudflare (que rotaciona a cada restart), então o valor
    # correto é dinâmico — manter vazio por padrão e adicionar via
    # override quando o hostname for conhecido.
    allowedHosts = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "example.trycloudflare.com" ];
      description = "Extra exact hostnames accepted by the Host-header/CORS check (PI_WEB_ALLOWED_HOSTS).";
    };

    # PI_WEB_IDLE_TIMEOUT_MS — padrão upstream é 600000 (10 min). O Pi
    # Coding Agent roda offline-first, então sessão inativa é desligada.
    idleTimeoutMs = lib.mkOption {
      type = lib.types.ints.unsigned;
      default = 600000;
      description = "Session idle timeout in ms (PI_WEB_IDLE_TIMEOUT_MS). 0 disables idle shutdown.";
    };

    shutdownDeadlineMs = lib.mkOption {
      type = lib.types.ints.unsigned;
      default = 5000;
      description = "Grace period for extension shutdown handling in ms (PI_WEB_SHUTDOWN_DEADLINE_MS).";
    };

    skipVersionCheck = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Disable upstream's update checks (PI_WEB_SKIP_VERSION_CHECK). True: o Nix fixa a versão; o check não faz sentido.";
    };

    openBrowser = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Open browser after start (PI_WEB_NO_OPEN=false). Service mode wants this disabled.";
    };

    environmentFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        Additional env vars via systemd EnvironmentFile= (e.g. PI_WEB_PASSWORD
        from sops-nix). Useful for anything not exposed as a typed option.
      '';
    };

    extraArgs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "--no-open" ];
      description = "Extra command-line arguments passed verbatim to the `pi-web` binary.";
    };
  };

  config = lib.mkIf cfg.enable {
    # Não conflitar com services.pi-web (@jmfederico) que também roda
    # neste host. Default 30141 está livre, mas se alguém setar 8584 ou
    # o que services.pi-web estiver usando, systemd vai falhar em bind
    # e gerar mensagens crípticas no log — assertion falha antes.
    assertions = [
      {
        assertion =
          !(config.services.pi-web.enable or false)
          || cfg.port != (config.services.pi-web.port or 8504);
        message = ''
          services.agegr-pi-web.port (${toString cfg.port}) colide com
          services.pi-web.port (${toString (config.services.pi-web.port or 8504)}).
          As duas instâncias escutam loopback mas não podem compartilhar a
          mesma porta — use uma porta diferente para o agegr.
        '';
      }
    ];

    systemd.services.agegr-pi-web = {
      description = "@agegr/pi-web — local web UI for the pi coding agent";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];

      # pi-web spawna `next start` como child e usa `process.execPath`
      # (resolve para `node`), então o node do nixpkgs precisa estar no
      # PATH do service. Os demais são as ferramentas que o pi-coding-agent
      # herda via shell.
      path = with pkgs; [ nodejs_22 git ripgrep bash coreutils ];

      environment = {
        HOME = home;
        NODE_ENV = "production";
        PI_WEB_HOSTNAME = cfg.host;
        PI_WEB_PORT = toString cfg.port;
        PI_WEB_IDLE_TIMEOUT_MS = toString cfg.idleTimeoutMs;
        PI_WEB_SHUTDOWN_DEADLINE_MS = toString cfg.shutdownDeadlineMs;
        # mkIf (não lib.optional) — quando não há hosts extra, o var some
        # do environment em vez de virar string vazia (alguns upstreams
        # tratam "" como "1 entrada vazia" em vez de "sem entradas").
        PI_WEB_ALLOWED_HOSTS = lib.mkIf (cfg.allowedHosts != [ ])
          (lib.concatStringsSep "," cfg.allowedHosts);
        PI_WEB_SKIP_VERSION_CHECK = if cfg.skipVersionCheck then "1" else "";
        PI_WEB_NO_OPEN = if cfg.openBrowser then "" else "1";
      };

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        WorkingDirectory = home;
        ExecStart = "${cfg.package}/bin/pi-web ${lib.escapeShellArgs cfg.extraArgs}";
        Restart = "always";
        RestartSec = "5s";

        # Sandbox moderada — same posture do services.pi-web-server do
        # @jmfederico. Não toca em /var/lib/dl-conn (read-only no proxy
        # via dl_conn), só lê ~/.pi/agent.
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = false; # precisa ler ~/.pi
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        RestrictSUIDSGID = true;
        LockPersonality = true;
        RestrictRealtime = true;
        RestrictAddressFamilies = [ "AF_INET" "AF_INET6" "AF_UNIX" ];

        # PI_WEB_PASSWORD (e qualquer outro secret) vem via `environmentFile`
        # (sops-nix secrets/secrets.yaml → sops.secrets."..."). NixOS aceita
        # apenas um EnvironmentFile por unit, então o caller usa um único
        # arquivo que contém PI_WEB_PASSWORD=... (e o que mais quiser).
        # mkIf aqui dentro do serviceConfig remove o attr quando
        # environmentFile é null — sem isso, unit falha em systemd-analyze
        # com "EnvironmentFile= null is not absolute".
        EnvironmentFile = lib.mkIf (cfg.environmentFile != null) cfg.environmentFile;
      };
    };
  };
}