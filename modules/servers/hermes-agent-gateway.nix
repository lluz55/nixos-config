# Hermes Agent (hermes-9router) num usuário isolado, dedicado.
#
# Objetivo: separar o agente do usuário interativo `lluz` — home própria,
# terminal tool com backend de container (rootless podman via dockerCompat,
# "docker" é o shim), config/segredos próprios. O uso segue interativo
# (`sudo -u <user> -H hermes-9router`); o serviço de gateway (mensageria
# 24/7) é criado mas fica DESLIGADO por padrão (gatewayEnable = false) —
# ligar quando houver uma plataforma de mensageria configurada.
#
# Por que isSystemUser + home em /var/lib em vez de /home:
# ProtectHome=true no serviço do gateway torna /home inteiro inacessível
# (inclusive o home do próprio usuário de serviço, não só o de `lluz`) —
# então o HERMES_9ROUTER_HOME do agente precisa morar fora de /home para
# ProtectHome funcionar sem quebrar o próprio serviço.
#
# Por que NoNewPrivileges NÃO está ligado no serviço do gateway:
# terminal.backend: docker aqui roda sobre podman rootless (via
# virtualisation.podman.dockerCompat). Contêineres rootless dependem de
# newuidmap/newgidmap, binários setuid-root — NoNewPrivileges bloqueia
# justamente a escalação que esses binários precisam para mapear as faixas
# de sub-UID, e RestrictNamespaces bloquearia a criação do user namespace
# do próprio podman. A fronteira de segurança aqui é o container (como o
# guia oficial do Hermes documenta para backend: docker), não o sandboxing
# do systemd sobre o processo do agente.
{
  config,
  lib,
  ...
}:
let
  cfg = config.services.hermesAgentGateway;
in {
  options.services.hermesAgentGateway = {
    enable = lib.mkEnableOption "usuário isolado dedicado para o Hermes Agent (hermes-9router)";

    package = lib.mkOption {
      type = lib.types.package;
      description = "Pacote hermes-9router (wrapper) a instalar para este usuário.";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "hermes-agent";
      description = "Nome do usuário de sistema dedicado ao Hermes Agent.";
    };

    stateDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/hermes-agent";
      description = "Home do usuário isolado (HERMES_9ROUTER_HOME fica em <stateDir>/.hermes-9router).";
    };

    subUidStart = lib.mkOption {
      type = lib.types.int;
      default = 300000;
      description = "Início da faixa de sub-UID/GID reservada para contêineres rootless deste usuário.";
    };

    profile = lib.mkOption {
      type = lib.types.str;
      default = "coder";
      description = "Perfil (--profile) do Hermes usado pelo serviço de gateway.";
    };

    gatewayEnable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Liga o serviço systemd do gateway (mensageria 24/7). Mantenha
        `false` até configurar uma plataforma (Telegram/Discord/etc.) e os
        allowlists de usuário — ver docs/user-guide/security. A unit é
        sempre criada; isso só controla `wantedBy`/autostart.

        Antes de ligar: (1) `TELEGRAM_ALLOWED_USERS`/`GATEWAY_ALLOWED_USERS`
        (ou DM pairing) em ${cfg.stateDir}/.hermes-9router/.env — sem
        allowlist explícito o gateway nega todo mundo por padrão, então não
        esquecer não quebra nada, mas também não abre a porta sem querer.
        (2) Rootless podman (terminal.backend: docker) dentro de um serviço
        systemd `User=` sem sessão de login pode não achar
        XDG_RUNTIME_DIR/`/run/user/<uid>`. Teste primeiro com
        `sudo -u ${cfg.user} -H hermes-9router` interativo (isso cria uma
        sessão de verdade); se o serviço falhar por isso, habilite linger
        (`loginctl enable-linger ${cfg.user}`).
      '';
    };

    apiKeyFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Caminho (ex.: sops secret) de um arquivo contendo NINE_ROUTER_API_KEY.";
    };
  };

  config = lib.mkIf cfg.enable {
    users.groups.${cfg.user} = {};
    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.user;
      home = cfg.stateDir;
      createHome = true;
      shell = "/run/current-system/sw/bin/bash";
      subUidRanges = [{startUid = cfg.subUidStart; count = 65536;}];
      subGidRanges = [{startGid = cfg.subUidStart; count = 65536;}];
      description = "Hermes Agent (usuário isolado, dedicado)";
    };

    # "docker" vira um shim para o podman rootless já habilitado
    # globalmente (virtualisation.podman.enable, ver hosts/configuration.nix)
    # — necessário para terminal.backend: docker funcionar sem Docker real.
    virtualisation.podman.dockerCompat = true;

    # Seed único: só grava config.yaml se ainda não existir, para não
    # sobrescrever ajustes feitos depois via `hermes config set`.
    system.activationScripts."hermesAgentGatewayConfig-${cfg.user}" = {
      deps = ["users" "groups"];
      text = ''
        install -d -m 0750 -o ${cfg.user} -g ${cfg.user} ${cfg.stateDir}
        install -d -m 0750 -o ${cfg.user} -g ${cfg.user} ${cfg.stateDir}/.hermes-9router
        cfgfile=${cfg.stateDir}/.hermes-9router/config.yaml
        if [ ! -f "$cfgfile" ]; then
          cat > "$cfgfile" <<'EOF'
        terminal:
          backend: docker
          docker_image: "nikolaik/python-nodejs:python3.11-nodejs20"
          docker_forward_env: []
        approvals:
          mode: smart
          timeout: 300
          cron_mode: deny
          single_query_mode: deny
          unattended_mode: deny
          deny:
            - "git push --force*"
            - "*curl*|*sh*"
            - "dd if=* of=/dev/*"
        security:
          redact_secrets: true
          tirith_enabled: true
        EOF
          chown ${cfg.user}:${cfg.user} "$cfgfile"
          chmod 0600 "$cfgfile"
        fi
      '';
    };

    systemd.services.hermes-gateway = {
      description = "Hermes Agent gateway (hermes-9router, usuário isolado — ver modules/servers/hermes-agent-gateway.nix)";
      wantedBy = lib.mkIf cfg.gatewayEnable ["multi-user.target"];
      after = ["network-online.target" "9router.service"];
      wants = ["network-online.target"];

      environment = {
        HERMES_9ROUTER_HOME = "${cfg.stateDir}/.hermes-9router";
      };

      path = [cfg.package];

      script =
        (lib.optionalString (cfg.apiKeyFile != null) ''
          export NINE_ROUTER_API_KEY="$(cat ${cfg.apiKeyFile})"
        '')
        + ''
          exec hermes-9router gateway run --profile ${cfg.profile}
        '';

      serviceConfig = {
        User = cfg.user;
        Group = cfg.user;
        WorkingDirectory = cfg.stateDir;
        Restart = "on-failure";
        RestartSec = 5;
        MemoryMax = "2G";

        # Hardening compatível com podman rootless (ver comentário no topo
        # do arquivo sobre por que NoNewPrivileges/RestrictNamespaces ficam
        # de fora):
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        ReadWritePaths = [cfg.stateDir];
      };
    };
  };
}
