# Relay Nostr local (strfry) para a sync E2E do dl_bestfin.
#
# O app dl_bestfin sincroniza dados cifrados (AES-256-GCM) publicando
# eventos Nostr kind:30078 (NIP-78) em relays configuráveis pelo usuário
# (ver docs/okf/features/sync.md no repo dl_bestfin). Por padrão ele usa
# só relays públicos de terceiros. Este módulo hospeda um relay adicional
# na rede local (binário `strfry`, mas com unit systemd própria em vez do
# módulo genérico `services.strfry` do nixpkgs -- aquele módulo cria a
# unit sempre como `strfry.service`, sem opção de renomear), para que os
# dispositivos do household sincronizem entre si na LAN sem depender de
# internet/relays externos. A unit systemd chama-se `bestfin_syncd`.
#
# Não expomos isso para a WAN: o host n100 já tem `networking.firewall`
# desabilitado em favor de um ruleset nftables próprio
# (hosts/n100/router/networking.nix), que aceita tudo vindo de
# `br-lan`/`br-cams`/`vl-mgmt`/`vl-home` e não abre nada novo para a WAN.
# Bind em 0.0.0.0 portanto só fica alcançável pelas VLANs já confiáveis.
#
# Autorização: como o conteúdo já é opaco (AES-256-GCM) e o cliente já
# filtra pull por `authors:[pubkey própria]`, a única coisa que vale a
# pena restringir aqui é *escrita* -- para o relay local não virar um
# lixo compartilhado caso outro dispositivo na rede tente publicar nele.
# strfry suporta isso nativamente via `relay.writePolicy.plugin`: um
# processo que recebe um evento JSON por linha no stdin e decide
# accept/reject por linha no stdout. Ver docs/plugins.md do strfry
# (https://github.com/hoytech/strfry).
{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.services.nostrSyncRelay;
  serviceName = "bestfin_syncd";
  stateDir = "/var/lib/${serviceName}";

  # Mesmo default do módulo services.strfry upstream (nixpkgs), copiado
  # aqui porque não usamos mais esse módulo (ele fixa o nome da unit como
  # `strfry.service`). Mantido em sync manualmente -- ver
  # nixos/modules/services/web-apps/strfry.nix no nixpkgs se precisar
  # revisar após um bump.
  defaultSettings = {
    db = stateDir;

    dbParams = {
      maxreaders = 256;
      mapsize = 10995116277760;
      noReadAhead = false;
    };

    events = {
      maxEventSize = 65536;
      rejectEventsNewerThanSeconds = 900;
      rejectEventsOlderThanSeconds = 94608000;
      rejectEphemeralEventsOlderThanSeconds = 60;
      ephemeralEventsLifetimeSeconds = 300;
      maxNumTags = 2000;
      maxTagValSize = 1024;
    };

    relay = {
      bind = "127.0.0.1";
      port = 7777;
      nofiles = 1000000;
      realIpHeader = "";

      info = {
        name = "strfry default";
        description = "This is a strfry instance.";
        pubkey = "";
        contact = "";
        icon = "";
        nips = "";
      };

      maxWebsocketPayloadSize = 131072;
      maxReqFilterSize = 200;
      autoPingSeconds = 55;
      enableTcpKeepalive = false;
      queryTimesliceBudgetMicroseconds = 10000;
      maxFilterLimit = 500;
      maxSubsPerConnection = 20;

      writePolicy = {
        plugin = "";
      };

      compression = {
        enabled = true;
        slidingWindow = true;
      };

      logging = {
        dumpInAll = false;
        dumpInEvents = false;
        dumpInReqs = false;
        dbScanPerf = false;
        invalidEvents = true;
      };

      numThreads = {
        ingester = 3;
        reqWorker = 3;
        reqMonitor = 3;
        negentropy = 2;
      };

      negentropy = {
        enabled = true;
        maxSyncEvents = 1000000;
      };
    };
  };

  settingsFormat = pkgs.formats.json { };

  settings = recursiveUpdate defaultSettings {
    relay = {
      bind = cfg.bind;
      port = cfg.port;
      info = {
        name = "dl_bestfin-sync (n100)";
        description = "Relay Nostr local para sync do household dl_bestfin na rede local.";
      };
      writePolicy.plugin = "${writePolicyScript}";
    };
  };

  configFile = settingsFormat.generate "config.json" settings;

  writePolicyScript = pkgs.writeScript "${serviceName}-write-policy" ''
    #!${pkgs.python3}/bin/python3
    import json
    import sys

    # Pubkeys Nostr (hex, 64 chars) autorizadas a publicar neste relay.
    # Mesmo formato exibido em "Sincronização > Identidade" no app
    # (toque na chave truncada para copiar o hex completo).
    AUTHORIZED = set(${builtins.toJSON cfg.authorizedPubkeys})

    def main():
        for line in sys.stdin:
            line = line.strip()
            if not line:
                continue
            event_id = ""
            pubkey = None
            try:
                req = json.loads(line)
                event = req.get("event", {})
                event_id = event.get("id", "")
                pubkey = event.get("pubkey")
            except Exception:
                pass

            if pubkey in AUTHORIZED:
                resp = {"id": event_id, "action": "accept"}
            else:
                resp = {
                    "id": event_id,
                    "action": "reject",
                    "msg": "blocked: pubkey nao autorizada neste relay",
                }
            sys.stdout.write(json.dumps(resp) + "\n")
            sys.stdout.flush()

    if __name__ == "__main__":
        main()
  '';
in
{
  options.services.nostrSyncRelay = {
    enable = mkEnableOption "relay Nostr local (strfry, unit bestfin_syncd) para sync do dl_bestfin na rede local";

    package = mkPackageOption pkgs "strfry" { };

    bind = mkOption {
      type = types.str;
      default = "0.0.0.0";
      description = "Endereço de bind do relay. 0.0.0.0 fica alcançável por todas as VLANs locais já confiáveis no firewall do n100.";
    };

    port = mkOption {
      type = types.port;
      default = 7777;
      description = "Porta TCP do relay (padrão do strfry).";
    };

    authorizedPubkeys = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "abcd1234..." ];
      description = ''
        Pubkeys Nostr em hex (64 chars) autorizadas a publicar (escrever)
        eventos neste relay. Cada identidade dl_bestfin (household) deriva
        uma única pubkey do mnemônico compartilhado -- normalmente uma
        entrada por household. Obtenha o valor no app em
        Sincronização > Identidade (toque na chave para copiar o hex
        completo). Leitura não é restrita: o cliente já filtra por
        `authors` na query de pull.
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [{
      assertion = cfg.authorizedPubkeys != [ ];
      message = "services.nostrSyncRelay.enable requer ao menos uma entrada em authorizedPubkeys.";
    }];

    users.users.${serviceName} = {
      description = "dl_bestfin sync relay daemon";
      group = serviceName;
      isSystemUser = true;
    };
    users.groups.${serviceName} = { };

    systemd.services.${serviceName} = {
      description = "dl_bestfin sync relay (strfry) -- unit própria, ver modules/servers/nostr-sync-relay.nix";
      wants = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        ExecStart = "${lib.getExe cfg.package} --config=${configFile} relay";
        User = serviceName;
        Group = serviceName;
        Restart = "on-failure";

        StateDirectory = serviceName;
        WorkingDirectory = stateDir;
        ReadWritePaths = [ stateDir ];

        LimitNOFILE = settings.relay.nofiles;

        PrivateTmp = true;
        PrivateUsers = true;
        PrivateDevices = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        NoNewPrivileges = true;
        MemoryDenyWriteExecute = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectKernelLogs = true;
        ProtectClock = true;
        ProtectProc = "invisible";
        ProcSubset = "pid";
        ProtectControlGroups = true;
        LockPersonality = true;
        RestrictSUIDSGID = true;
        RemoveIPC = true;
        RestrictRealtime = true;
        ProtectHostname = true;
        CapabilityBoundingSet = "";
        SystemCallFilter = [ "@system-service" ];
        SystemCallArchitectures = "native";
      };
    };
  };
}
