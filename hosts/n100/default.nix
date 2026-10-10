{ pkgs, config, lib, unstable, inputs, minimax-code-pkg, ... }:
let
  gasketRev = "09385d485812088e04a98a6e1227bf92663e0b59";
  gasketPkg = (pkgs.gasket.overrideAttrs (final: prev: {
    version = builtins.substring 0 6 gasketRev;
    src = pkgs.fetchFromGitHub {
      owner = "google";
      repo = "gasket-driver";
      rev = gasketRev;
      hash = "sha256-fcnqCBh04e+w8g079JyuyY2RPu34M+/X+Q8ObE+42i4=";
    };
  })).override {
    kernel = config.boot.kernelPackages.kernel;
  };
  # Hardening extra para os units systemd do módulo services.hermes-agent
  # (gateway + dashboard) — ver comentário junto de services.hermes-agent
  # mais abaixo. mkForce em tudo evita "conflicting definitions" tanto nos
  # campos que o módulo upstream já define (ex.: ProtectHome) quanto nos
  # novos, sem precisar rastrear qual é qual.
  hermesHardeningOverrides = lib.mapAttrs (_: lib.mkForce) {
    ProtectHome = true;
    PrivateDevices = true;
    PrivateUsers = true;
    ProtectKernelTunables = true;
    ProtectKernelModules = true;
    ProtectKernelLogs = true;
    ProtectClock = true;
    ProtectProc = "invisible";
    ProcSubset = "pid";
    ProtectControlGroups = true;
    ProtectHostname = true;
    RestrictNamespaces = true;
    LockPersonality = true;
    RestrictSUIDSGID = true;
    RemoveIPC = true;
    RestrictRealtime = true;
    CapabilityBoundingSet = "";
    SystemCallFilter = [ "@system-service" ];
    SystemCallArchitectures = "native";
  };
  # Chaves que o Nix apenas SEMEIA no config.yaml: entram só quando ainda
  # não existem. Diferente de services.hermes-agent.settings, que o merge de
  # activation do módulo reimpõe a cada rebuild — o que sobrescreveria toda
  # escolha feita no dashboard. Tudo que precisa ser trocável em runtime mora
  # aqui, e não em `settings`.
  hermesConfigSeed = {
    # Sem isto o config.yaml nasce sem `_config_version` e
    # check_config_version() (hermes_cli/config.py) lê 0 — abaixo do
    # SUPPORT_FLOOR_VERSION = 12 de config_migrations.py. Aí o hermes se
    # recusa a auto-migrar o schema e /api/status reporta config_version 0
    # contra latest_config_version 44. O valor é o `_config_version` do
    # config_defaults.py do hermes 0.21.2; como é seed, uma migração futura
    # que o próprio hermes rodar (agora que a escrita está destravada) pode
    # subir esse número sem o Nix puxar de volta.
    _config_version = 44;

    # Modelo ativo. Trocável pelo seletor do dashboard e pelo `/model`, então
    # fica fora de `settings`. É um dos ids que o 9router expõe em
    # GET /v1/models.
    model.default = "cc/claude-sonnet-5";
  };
  seedHermesConfig = pkgs.writeScript "seed-hermes-config" ''
    #!${pkgs.python3.withPackages (ps: [ ps.pyyaml ])}/bin/python3
    import json
    import pathlib
    import sys
    import yaml

    seed = json.loads(sys.argv[1])
    live_path = pathlib.Path(sys.argv[2])
    live = (yaml.safe_load(live_path.read_text()) if live_path.exists() else {}) or {}

    def seed_missing(target, values):
        changed = False
        for key, value in values.items():
            if isinstance(value, dict):
                child = target.get(key)
                if not isinstance(child, dict):
                    child = {}
                    target[key] = child
                    changed = True
                changed = seed_missing(child, value) or changed
            elif key not in target:
                target[key] = value
                changed = True
        return changed

    if seed_missing(live, seed):
        temporary = live_path.with_suffix(".yaml.seed-tmp")
        temporary.write_text(yaml.safe_dump(live, sort_keys=False, allow_unicode=True))
        temporary.chmod(0o660)
        temporary.replace(live_path)
  '';
  hound-mcp-pkg = pkgs.callPackage ../../pkgs/hound-mcp/package.nix { };
  omniroute-pkg = pkgs.callPackage ../../pkgs/omniroute/package.nix { };
  dlConnConfigSeed = ./dl-conn-config.yaml;
  syncDlConnServices = pkgs.writeScript "sync-dl-conn-services" ''
    #!${pkgs.python3.withPackages (ps: [ ps.pyyaml ])}/bin/python3
    import pathlib
    import sys
    import yaml

    seed_path = pathlib.Path(sys.argv[1])
    live_path = pathlib.Path(sys.argv[2])
    seed = yaml.safe_load(seed_path.read_text()) or {}
    live = yaml.safe_load(live_path.read_text()) or {}

    # Só as rotas marcadas abaixo são gerenciadas pelo Nix. Estado mutável do
    # dl_conn, especialmente nostr.authorizedNpubs, permanece intocado.
    managed_ids = {"hermes", "omni", "zellij"}
    desired = {
        service["id"]: service
        for service in seed.get("services", [])
        if service.get("id") in managed_ids
    }
    services = live.setdefault("services", [])
    merged = []
    seen = set()
    for service in services:
        service_id = service.get("id")
        if service_id in desired:
            merged.append(desired[service_id])
            seen.add(service_id)
        else:
            merged.append(service)
    merged.extend(desired[service_id] for service_id in desired if service_id not in seen)

    if merged != services:
        live["services"] = merged
        temporary = live_path.with_suffix(".yaml.tmp")
        temporary.write_text(yaml.safe_dump(live, sort_keys=False, allow_unicode=True))
        temporary.chmod(0o640)
        temporary.replace(live_path)
  '';
  opencode-pkg = pkgs.callPackage ../../pkgs/opencode/package.nix {opencode = unstable.opencode;};
  dl-home-control = builtins.getFlake "/home/lluz/dev/dl_home_control";
in
with lib;{
  imports = [
    ./hardware-configuration.nix
    ./router
    inputs.vscode-server.nixosModules.default
    inputs.dl-conn.nixosModules.default
    inputs.hermes-agent.nixosModules.default
    dl-home-control.nixosModules.default
    inputs.zellij-web-wrapper.nixosModules.default
    ../../pkgs/9router/module.nix
    ../../pkgs/omniroute/module.nix
    ../../pkgs/dsh/module.nix
    ../../pkgs/pi-web/module.nix
    ../../pkgs/agent-of-empires/module.nix
    # pi-web-simple no dl_conn: segunda instância do Pi Coding Agent Web UI,
    # variante @agegr/pi-web (porta 30141, distinta da @jmfederico/pi-web
    # em 8584). Bind loopback — só dl_conn alcança. PI_WEB_ALLOWED_HOSTS
    # fica vazio por enquanto; ver comentário em pkgs/agegr-pi-web/module.nix.
    ../../pkgs/agegr-pi-web/module.nix
  ];

  console = {
    font = "Lat2-Terminus16";
    keyMap = "br-abnt2";
  };

  # 15GB de RAM sem swap nenhum (hardware-configuration.nix declara
  # swapDevices = []) e systemd-oomd ativo: qualquer pico de memória vira
  # SIGKILL na hora em vez de reclaim gradual — foi o que matou o build do
  # dl_conn durante o rebuild de hoje. 8G de arquivo em disco (261G livres
  # em /) dá essa folga; o NixOS cria o arquivo sozinho na ativação se ele
  # ainda não existir.
  swapDevices = [
    { device = "/var/lib/swapfile"; size = 8192; }
  ];

  profiles.desktop.enable = false;
  gnome.enable = false;
  # profiles.rtl88x2bu.enable = true;
  hass.enable = true;
  frigate.enable = true;
  glances.enable = true;
  twingate.enable = true;
  cloudflaredConnectors = {
    enable = true;
    tunnels = {
      ssh = { };
      haby = { };
    };
  };

  services.netbird.enable = true;
  programs.mosh.enable = true;

  # llama.cpp — API OpenAI-compatible nas redes confiáveis e pelo conector
  # Twingate local. O firewall libera a porta somente nas VLANs confiáveis;
  # WAN e vl-guests continuam bloqueadas. O router mode descobre todos os
  # GGUF em /home/lluz/.models e os anuncia em GET /v1/models. Para um
  # modelo com visão, o GGUF e o projetor ficam LADO A LADO no diretório
  # plano — o loader do models-dir NÃO desce em subdiretórios, então um par
  # em `~/.models/LFM2-VL-450M/` seria invisível. O --mmproj-auto (default:
  # enabled) só pareia o projetor em auto-scan quando o GGUF está no nível
  # raiz de --models-dir (em modo -hf a flag é no-op):
  #
  #   ~/.models/
  #     LFM2-VL-450M-Q4_0.gguf
  #     mmproj-LFM2-VL-450M-Q8_0.gguf
  #
  # Com o par no lugar, `GET /v1/models` expõe
  # `architecture.input_modalities = ["text","image"]` na entrada do
  # modelo — esse é o sinal real de multimodal (não existe
  # `capabilities.multimodal` no payload do llama-server). Atenção ao elo
  # seguinte: o 9router 0.5.69 NÃO lê `architecture.*` do upstream, só herda
  # `capabilities` explícito e, fora isso, decide visão por
  # getCapabilitiesForModel (patterns/catálogo/regex de nome). GGUFs locais
  # vindos do llama.cpp ficam sem vision no 9router enquanto o projetor não
  # aparece no /v1/models do llama — verificado em 2026-09-12 (llama-cpp
  # 0.3.0): as 4 entradas anunciam input_modalities=["text"].
  # Modelos não entram no Nix store; após adicionar/remover arquivos, reinicie
  # o unit para atualizar o catálogo.
  #
  # Com 16 GB de RAM, models-max = 1 impede que os dois modelos permaneçam
  # residentes juntos. O llama-server carrega automaticamente o modelo pedido
  # no campo `model` da requisição e troca o modelo carregado quando preciso.
  # O serviço usa o usuário lluz para poder ler os arquivos privados do
  # diretório de modelos; ProtectHome permanece somente-leitura.
  services.llama-cpp = {
    enable = true;
    openFirewall = false;
    settings = {
      host = "0.0.0.0";
      port = 8081;
      models-dir = "/home/lluz/.models";
      models-max = 1;
      # --mmproj-auto é default-enabled no llama-server; declarado aqui para
      # documentar a dependência do pareamento: sem o mmproj ao lado do GGUF,
      # update_caps() zera multimodal e input_modalities fica ["text"].
      mmproj-auto = true;
      # Parâmetros de execução aplicados a cada modelo carregado pelo router.
      ctx-size = 4096;
      threads = 8;
      threads-batch = 8;
      batch-size = 512;
      ubatch-size = 512;
      mlock = true;
      cache-type-k = "q8_0";
      cache-type-v = "q8_0";
      jinja = true;
      parallel = 1;
    };
  };

  systemd.services.llama-cpp = {
    # Uma configuração pode ser aplicada antes do diretório de modelos existir.
    # Nesse caso o unit fica inativo, em vez de reiniciar continuamente.
    unitConfig.ConditionPathIsDirectory = "/home/lluz/.models";
    serviceConfig = {
      # DynamicUser vira false aqui para o unit ler GGUFs privados em
      # /home/lluz/.models — mas isso DESTROI TAMBÉM os outros mkForce
      # abaixo se listado junto; portanto cada override é seletivo, campo a
      # campo, com comentário próprio. NUNCA colapse estes três em um bloco
      # genérico "endurecer sandbox": DynamicUser = false anula este bloco
      # inteiro e flags novas em services.llama-cpp.settings (ex.:
      # mmproj-auto) somem silenciosamente do ExecStart.
      DynamicUser = lib.mkForce false;
      User = "lluz";
      Group = "users";
      # ProtectHome precisa ser só read-only (não `true`, que esconde
      # /home): o router lê os GGUF sob /home/lluz/.models.
      ProtectHome = lib.mkForce "read-only";
    };
  };

  # 9Router — gateway AI local, ouvindo na LAN (porta 20128 default do
  # próprio 9router; sem --host explícito o CLI já usa 0.0.0.0).
  services."9router" = {
    enable = true;
  };

  # OmniRoute — o flake upstream expõe apenas devShell, então o pacote é o
  # wrapper reprodutível de pkgs/omniroute sobre a release npm correspondente.
  # Fica apenas no loopback; o acesso externo passa pelo Zero-Trust do dl_conn.
  services.omniroute = {
    enable = true;
    package = omniroute-pkg;
    port = 20129;
    host = "127.0.0.1";
  };

  # Zellij Web Wrapper — terminal web xterm.js + PTY para sessões Zellij.
  # Fica apenas no loopback; o acesso externo passa pelo Zero-Trust do dl_conn.
  services.zellij-web = {
    enable = true;
    port = 3001;
  };

  # DeepSeek Harness (dsh) — web profile. Bind só em 127.0.0.1 (upstream
  # recusa --host 0.0.0.0 de propósito); acesse via SSH -L, Tailscale ou
  # Netbird já configurados neste host.
  users.groups.dsh-access = { };
  systemd.services.dl-conn.serviceConfig.SupplementaryGroups = [ "dsh-access" ];

  services.dsh = {
    enable = true;
    group = "dsh-access";

    # O 9router é rota hand-declared do adapter pi-ai: `models` precisa estar
    # listado na mão em ~/.dsh/settings.yaml e envelhece sozinho. O timer
    # re-lê GET /v1/models e reescreve só essa lista.
    modelSync = {
      enable = true;
      baseURL = "http://localhost:20128/v1";
      interval = "daily";
    };
    providers = {
      "9router" = {
        name = "9router";
        baseURL = "http://localhost:20128/v1";
        apiKey = null;
        models = [ ];
      };
    };
  };

  # Reusa pi-web-server/pi-web-sessiond como systemd system services (user
  # lluz, data dir ~/.pi-web). Bind 0.0.0.0:8584; o firewall
  # (router/firewall.nix) abre a porta só pras VLANs confiáveis (WAN drop,
  # vl-guests sem accept), então não expõe pra fora nem pros guests.
  services.pi-web = {
    enable = true;
    host = "0.0.0.0";

    # Mesmo raciocínio do dsh: 9router é provider custom em models.json, sem
    # catálogo embutido, então `models` precisa ser re-sincronizado.
    modelSync = {
      enable = true;
      baseURL = "http://localhost:20128/v1";
      interval = "daily";
    };
    port = 8584;
  };

  # Segunda instância da Pi Coding Agent Web UI — variante @agegr/pi-web
  # (npx @agegr/pi-web, porta 30141). Roda LADO A LADO com `services.pi-web`
  # (@jmfederico/pi-web, porta 8584):
  #
  #   - portas distintas (30141 vs 8584), sem colisão
  #   - data dirs distintas: services.pi-web usa /home/lluz/.pi-web
  #     (dataDir default do pkgs/pi-web/module.nix); services.agegr-pi-web
  #     não tem data dir próprio — o binário grava só no .next/ interno do
  #     pacote e nada em $HOME (verificado em node_modules/@agegr/pi-web/bin/)
  #   - mesmo user (lluz), mesmo /home/lluz (cwd) — as duas UIs compartilham
  #     `~/.pi/agent` (read-only viewers das sessões do pi CLI)
  #   - systemd units independentes: falhas de uma não derrubam a outra
  #
  # O dl_conn expõe o agegr como `/pi-web-simple` (drop-in
  # `~/.config/dl-conn/services.d/pi-web-simple.yaml`). Bind loopback (default
  # 127.0.0.1) — só dl_conn alcança; firewall (router/firewall.nix) não
  # precisa abrir 30141.
  #
  # PI_WEB_ALLOWED_HOSTS fica vazio: o upstream rejeita Host headers de
  # proxies não-listados (ver comentário em pkgs/agegr-pi-web/module.nix). Para
  # destravar o acesso via dl_conn, adicione o hostname trycloudflare em
  # `allowedHosts` (lembrando de atualizar a cada restart do dl_conn).
  services.agegr-pi-web = {
    enable = true;
    user = "lluz";
    port = 30141;
    # PI_WEB_ALLOWED_HOSTS vem do arquivo gerado em runtime pelo timer
    # abaixo (services/systemd/timers + services/update-pi-web-allowed-hosts).
    # O dl_conn expõe `/api/host/tunnel-url` (commit dl_conn 47c9b16) e o
    # timer curl + extrai + escreve aqui. Em restart do dl_conn ou rotação
    # do trycloudflare URL, o arquivo muda e agegr-pi-web é reiniciado pelo
    # mesmo script. Sem edição manual a cada rotação.
    environmentFile = "/var/lib/dl-conn/tunnel-url.env";
  };

  # Timer + script que mantém `tunnel-url.env` em sincronia com a URL atual
  # do tunnel do dl_conn. Curl no endpoint local, comparação idempotente
  # com o conteúdo atual do arquivo, escrita + restart do agegr-pi-web só
  # quando a URL muda.
  #
  # Por que timer e não systemd.path: o dl_conn não escreve a URL em disco
  # (só na memória do handler Nostr); um watcher em inotify teria que
  # apontar para um arquivo que ele mesmo não cria. O poll de 30s é barato
  # (curl localhost + comparação de string) e a latência de rotação de
  # 30s é aceitável.
  systemd.timers.update-pi-web-allowed-hosts = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "10s";
      OnUnitActiveSec = "30s";
      AccuracySec = "1s";
    };
  };
  systemd.services.update-pi-web-allowed-hosts = {
    serviceConfig = {
      Type = "oneshot";
      ExecStart = let
        script = pkgs.writeShellScriptBin "update-pi-web-allowed-hosts" ''
          set -euo pipefail

          url_file="/var/lib/dl-conn/tunnel-url.env"
          tmp_file="''${url_file}.tmp"

          # dl_conn escuta em 127.0.0.1:9099 (HTTP local). Endpoint do
          # commit dl_conn 47c9b16 — GET /api/host/tunnel-url responde
          # {"url":"https://...trycloudflare.com"}. Sem auth.
          response=$(${pkgs.curl}/bin/curl \
            --silent --show-error --fail --max-time 5 \
            http://127.0.0.1:9099/api/host/tunnel-url 2>/dev/null) || {
            echo "dl_conn endpoint unreachable, skipping this tick" >&2
            exit 0
          }

          # Extrai o campo "url" via sed (evita depender de jq).
          url=$(printf '%s' "$response" | ${pkgs.gnused}/bin/sed -n 's/.*"url":"\([^"]*\)".*/\1/p')

          # dl_conn retorna url="" antes do tunnel estar pronto — não
          # sobrescreve arquivo válido com string vazia.
          if [ -z "$url" ]; then
            echo "empty tunnel url, skipping this tick" >&2
            exit 0
          fi

          # PI_WEB_ALLOWED_HOSTS recebe só o hostname (sem scheme, sem
          # path). trycloudflare retorna https://abc.trycloudflare.com —
          # strip prefixo.
          hostname=''${url#https://}
          hostname=''${hostname#http://}
          hostname=''${hostname%%/*}

          # Idempotência: se o arquivo já tem o valor correto, não escreve
          # (evita restart desnecessário do agegr-pi-web quando o timer
          # dispara e o valor não mudou).
          if [ -f "$url_file" ] && \
             [ "$(cat "$url_file" 2>/dev/null || true)" = "PI_WEB_ALLOWED_HOSTS=$hostname" ]; then
            exit 0
          fi

          # Escreve atomicamente (rename preserva o inode — watchers no
          # agegr-pi-web via EnvironmentFile= recebem o valor novo sem
          # race de leitura de meio-arquivo).
          echo "PI_WEB_ALLOWED_HOSTS=$hostname" > "$tmp_file"
          mv -f "$tmp_file" "$url_file"

          # Reload do agegr-pi-web é necessário: EnvironmentFile é lido na
          # inicialização do unit, não hot-raspado. try-reload-or-restart
          # prefere reload quando suportado (não é o caso aqui) e cai
          # para restart automaticamente.
          ${pkgs.systemd}/bin/systemctl try-reload-or-restart agegr-pi-web.service || true

          echo "Updated PI_WEB_ALLOWED_HOSTS=$hostname (tunnel URL rotated)"
        '';
      in "${script}/bin/update-pi-web-allowed-hosts";
    };
  };

  # AGENT OF EMPIRES — session manager TUI/web para os agentes CLI.
  # Bind no loopback (--no-auth), acesso remoto pelo dl-conn ou SSH -L.
  # Detector automático de codex, opencode, antigravity, claude e pi.
  # MiniMax Code entra como custom agent com structured view via ACP —
  # `mcode acp` herda o adapter `claude` para detecção de status.
  #
  # IMPORTANTE: registra `mcode` (não só `minimax-code`). O AoE
  # auto-detecta `mcode` no PATH e expõe esse nome no picker do TUI/web
  # ANTES do custom — quando o usuário clica em "mcode", o AoE spawna
  # `mcode` puro (que abre o TUI interativo, não fala ACP) e o
  # handshake trava 30s. Sobrescrever `mcode` com o mesmo command +
  # acpCommand garante que qualquer um dos dois nomes funcione no
  # structured view.
  services.agent-of-empires = {
    enable = true;
    host = "127.0.0.1";
    port = 25809;
    noAuth = true;
    customAgents = {
      mcode = {
        command = "mcode";
        acpCommand = "mcode acp";
        detectAs = "claude";
      };
      minimax-code = {
        command = "mcode";
        acpCommand = "mcode acp";
        detectAs = "claude";
      };
    };
  };

  # Hermes Agent — gateway e dashboard declarativos pelo módulo NixOS
  # oficial. O dashboard fica somente no loopback: o dl_conn é a única
  # entrada remota e já aplica autenticação/autorização Nostr antes do proxy.
  # Hermes suporta prefixos de reverse proxy, portanto /hermes funciona sem
  # bind público e sem abrir a porta 9119 no firewall.
  #
  # sops."hermes.env": a API key emitida no dashboard do 9router
  # (http://127.0.0.1:20128 → API Keys). GET /v1/models responde sem auth,
  # mas POST /v1/chat/completions devolve 401 sem ela — era o segundo motivo
  # do hermes não conseguir conversar mesmo com o provider resolvido. O
  # segredo é um arquivo .env de uma linha: OPENAI_API_KEY=<key>.
  sops.secrets."hermes.env" = {
    owner = "hermes";
    group = "hermes";
  };

  services.hermes-agent = {
    enable = true;
    addToSystemPackages = true;
    backend = {
      mode = "dashboard";
      host = "127.0.0.1";
      port = 9119;
    };
    settings = {
      terminal.backend = "local";

      # Provider nomeado e descoberto dinamicamente pelo GET /v1/models do
      # 9router. Assim os modelos locais e remotos agregados pelo gateway
      # aparecem no seletor do dashboard e no `/model custom:9router:<id>`,
      # sem duplicar uma lista estática no Nix. `key_env` é o que
      # hermes_cli/providers.py lê pra achar a credencial do provider
      # nomeado; sem ele o gateway loga "named custom provider '9Router
      # local' has no resolvable api_key ... will 401".
      providers."9router" = {
        name = "9Router local";
        api = "http://127.0.0.1:20128/v1";
        transport = "openai_chat";
        discover_models = true;
        key_env = "OPENAI_API_KEY";
      };

      # `provider: custom` NÃO serve aqui, e esse era o motivo do dashboard
      # web abrir direto no painel "Setup Required". A TUI web chama o RPC
      # setup.status → free_tier_bootstrap → resolve_provider("auto"), e o
      # degrau que lê o config.yaml (_config_model_provider, hermes_cli/
      # auth.py) só aceita o valor se ele estiver no PROVIDER_REGISTRY.
      # "custom" não está — só vale quando pedido explicitamente por
      # --provider na linha de comando. Resultado: AuthError
      # no_provider_configured, provider_configured=false, painel de setup.
      #
      # "openai-api" está no registry e é o caminho OpenAI-compatible
      # genérico. Ele NÃO lê `model.base_url` (isso só vale pro provider
      # "actual"): a URL sai de OPENAI_BASE_URL, definido em `environment`
      # abaixo. O base_url segue aqui só como documentação do destino real.
      model = {
        provider = "openai-api";
        base_url = "http://127.0.0.1:20128/v1";
      };
    };

    # Vira $HERMES_HOME/.env na activation. OPENAI_BASE_URL é obrigatório:
    # sem ele o provider openai-api cai no default https://api.openai.com/v1.
    environment = {
      OPENAI_BASE_URL = "http://127.0.0.1:20128/v1";
    };

    # Anexado ao mesmo .env, mas fora do /nix/store (que é legível por
    # qualquer usuário).
    environmentFiles = [ config.sops.secrets."hermes.env".path ];

    extraPackages = with pkgs; [ bash coreutils git ripgrep nodejs_22 ];
  };

  # ── Configuração editável em runtime ──────────────────────────────────
  # O módulo instala $HERMES_HOME/.managed com "nixos" e passa
  # HERMES_MANAGED=true pros units. Isso liga o write-lock de
  # hermes_cli/config.py: save_config(), set_config_value() e
  # edit_config() recusam QUALQUER gravação — o seletor de modelo do
  # dashboard, o `/model` da TUI e o `hermes config set` todos falham. Com
  # isso desligado, o config.yaml volta a ser gravável e o merge do Nix
  # continua reimpondo, a cada rebuild, só as chaves de `settings` acima.
  #
  # HERMES_HOME_MODE existe porque fora do modo managed o hermes chama
  # _secure_dir() e faz chmod 0700 no $HERMES_HOME — o que tiraria o acesso
  # do grupo `hermes` (e portanto do lluz, ver extraGroups abaixo). 2770
  # mantém setgid + grupo.
  systemd.services.hermes-agent.environment = {
    HERMES_MANAGED = lib.mkForce "false";
    HERMES_HOME_MODE = "2770";
  };
  systemd.services.hermes-backend.environment = {
    HERMES_MANAGED = lib.mkForce "false";
    HERMES_HOME_MODE = "2770";
  };

  system.activationScripts.hermes-local-overrides = {
    # Roda depois do snippet do módulo, que é quem escreve config.yaml e
    # .managed. Inverter a ordem faria o módulo desfazer tudo isto.
    deps = [ "hermes-agent-setup" ];
    text = ''
      ${seedHermesConfig} ${lib.escapeShellArg (builtins.toJSON hermesConfigSeed)} \
        /var/lib/hermes/.hermes/config.yaml
      chown hermes:hermes /var/lib/hermes/.hermes/config.yaml
      chmod 0660 /var/lib/hermes/.hermes/config.yaml

      # O CLI interativo não enxerga o HERMES_MANAGED dos units, então ele
      # lê este marcador. "false" está em _MANAGED_FALSE_VALUES, logo
      # get_managed_system() devolve None e is_managed() é falso também no
      # shell. Efeito colateral aceito: `hermes update` deixa de ser
      # recusado — não rode, a atualização é pelo flake input.
      printf 'false\n' > /var/lib/hermes/.hermes/.managed
      chown hermes:hermes /var/lib/hermes/.hermes/.managed
      chmod 0644 /var/lib/hermes/.hermes/.managed
    '';
  };

  # Duas rotinas do hermes apertam permissões depois de cada gravação e
  # nenhuma das duas tem escape:
  #
  #  - _secure_file() (hermes_cli/config.py) faz chmod 0600 no config.yaml e
  #    no .env. Diferente de _secure_dir(), não olha HERMES_HOME_MODE.
  #  - _save_auth_store() → _write_private_file_atomic() →
  #    secure_parent_dir() (hermes_constants.py) faz chmod 0700 no PAI do
  #    auth.json, que é o próprio $HERMES_HOME. Sem checagem de is_managed()
  #    e sem HERMES_HOME_MODE. Isso não aparecia antes só porque o provider
  #    nunca resolvia e o auth store nunca era escrito; agora que resolve, o
  #    home vira 0700 alguns segundos depois do start e o grupo `hermes`
  #    (logo o lluz, ver extraGroups abaixo) perde o acesso.
  #
  # secure_parent_dir() roda ANTES do rename atômico do auth.json, então o
  # inotify do PathChanged dispara depois dela e o chmod daqui é o último a
  # valer. A alternativa seria abrir mão do home compartilhado por grupo e
  # rodar o CLI com `sudo -u hermes`.
  systemd.paths.hermes-config-perms = {
    wantedBy = [ "multi-user.target" ];
    pathConfig.PathChanged = [
      "/var/lib/hermes/.hermes/config.yaml"
      "/var/lib/hermes/.hermes/.env"
      "/var/lib/hermes/.hermes/auth.json"
    ];
  };
  systemd.services.hermes-config-perms = {
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "hermes-config-perms" ''
        chmod 2770 /var/lib/hermes/.hermes || true
        for file in /var/lib/hermes/.hermes/config.yaml /var/lib/hermes/.hermes/.env; do
          [ -e "$file" ] && chmod 0660 "$file"
        done
        exit 0
      '';
    };
  };

  # addToSystemPackages instala o CLI `hermes` no PATH do lluz, mas
  # $HERMES_HOME (/var/lib/hermes/.hermes) é 2770 hermes:hermes — sem
  # este extraGroups, `hermes setup`/`hermes setup model` rodado como
  # lluz não enxerga o diretório (Permissão negada) e o setup nunca
  # persiste, reaparecendo a cada execução.
  users.users.lluz.extraGroups = [ "hermes" ];

  # Hardening extra em cima do módulo oficial (que já roda sob usuário
  # dedicado `hermes` com ProtectSystem=strict e ReadWritePaths restrito ao
  # próprio stateDir). Este é o único host onde o Hermes fica atrás de uma
  # superfície de rede real (dl-conn expõe o dashboard, inclusive um
  # terminal com backend "local"), então o mesmo padrão do
  # modules/servers/nostr-sync-relay.nix se aplica: derrubar o que não é
  # usado (capabilities, kernel tunables, namespaces) sem tocar no que o
  # Node precisa pra rodar.
  #
  # MemoryDenyWriteExecute fica de fora de propósito: o hermes roda em
  # Node.js/V8, que precisa de páginas RWX pro JIT — essa diretiva
  # derrubaria o serviço na inicialização.
  #
  # ProtectHome=true substitui o default do módulo (false): o
  # workingDirectory do hermes vive em ${cfg.stateDir}, nunca em /home, e
  # ele não tem por que enxergar /home/lluz.
  #
  # Ainda não testado neste host: o terminal "local" do dashboard spawna
  # PTYs, o que pode exigir syscalls fora de @system-service. Se o terminal
  # falhar depois do rebuild, comece afrouxando SystemCallFilter antes de
  # PrivateUsers/RestrictNamespaces.
  systemd.services.hermes-agent.serviceConfig = hermesHardeningOverrides;
  systemd.services.hermes-backend.serviceConfig = hermesHardeningOverrides;

  services.prometheus = {
    exporters = {
      node = {
        enable = true;
        # TODO test perf impact of these modules
        enabledCollectors = [
          "arp"
          "hwmon"
          "cpu"
          "diskstats"
          "ethtool"
          "interrupts"
          "ksmd"
          "lnstat"
          "mountstats"
          "processes"
          "systemd"
          "wifi"
          "tcpstat"
          "netdev"
          "netstat"
          "network_route"
          "netclass"
          "sockstat"
          "stat"
          "conntrack"
        ];
        port = 9002;
      };
    };
  };
  environment.systemPackages = with unstable; [
    lm_sensors
    tailscale
    arp-scan
    glances
    btop
    usbutils

    nixfmt

    netbird
    sops
    opencode-pkg
    config.home-manager.users.lluz.programs.pi.coding-agent.finalPackage
    config.services.pi-web.package
    omniroute-pkg

    config.services.dl-conn.package
    minimax-code-pkg
  ] ++ [ hound-mcp-pkg ];

  services.twingate.enable = lib.mkForce false;

  boot = {
    kernelPackages = pkgs.linuxKernel.packages.linux_zen;
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
      timeout = 2;
    };
    extraModulePackages = [ config.boot.kernelPackages.gasket ];
    kernelModules = [ "gasket" "apex" ];
    tmp = {
      useTmpfs = true;
      tmpfsSize = "30%";
    };
  };

  services.udev.extraRules = ''
    SUBSYSTEM=="apex", MODE="0660", GROUP="users"
  '';

  hardware.acpilight.enable = true;

  services.vaultwarden = {
    enable = true;
    config = {
      ROCKET_ADDRESS = "10.0.66.1";
      ROCKET_PORT = 8222;
    };
  };

  # dl_conn — Cloudflare Tunnel + Nostr signaling gateway
  sops.secrets."nostr/dl-conn-key" = {
    owner = "dl-conn";
    group = "dl-conn";
  };

  services.dl-conn = {
    enable = true;
    secretFile = config.sops.secrets."nostr/dl-conn-key".path;

    # servicesDir sob ~/.config/dl-conn/services.d: usuário escreve drop-ins
    # direto, daemon bind-mounta read-only (BindReadOnlyPaths no módulo) e
    # o watcher (3s) recarrega sem reload de unit nem rotação de URL. Sem
    # sudo, sem nixos-rebuild para adicionar/remover serviço.
    servicesDir = "/home/lluz/.config/dl-conn/services.d";

    # Config gravável em vez de gerada no /nix/store (read-only): permite
    # `dl_conn npubs add <npub>` autorizar dispositivos em runtime, sem
    # nixos-rebuild + restart do serviço — o que derrubaria o túnel
    # Cloudflare efêmero atual e a URL trycloudflare.com já distribuída.
    #
    # O módulo não popula este arquivo sozinho. A regra systemd.tmpfiles
    # abaixo (tipo "C") copia ./dl-conn-config.yaml para cá só na primeira
    # vez (se o destino já existir, não é sobrescrito) — assim o estado
    # inicial (relays, serviços, npubs autorizadas em 2026-08-27) semeia o
    # arquivo automaticamente no switch, mas edições feitas via
    # `npubs add` em runtime nunca são perdidas em switches futuros.
    configFile = "/var/lib/dl-conn/config.yaml";
  };

  systemd.tmpfiles.rules = [
    "C /var/lib/dl-conn/config.yaml 0640 dl-conn dl-conn - ${dlConnConfigSeed}"
  ];

  # O arquivo gravável já existe no n100, portanto a regra "C" acima não
  # acrescentaria novas rotas. Antes de iniciar, mescla somente os serviços
  # explicitamente gerenciados pelo script (Hermes e Omni), preservando npubs e
  # quaisquer outras alterações feitas em runtime.
  systemd.services.dl-conn.serviceConfig.ExecStartPre =
    "${syncDlConnServices} ${dlConnConfigSeed} /var/lib/dl-conn/config.yaml";

  # dl_home_control — daemon ponte MQTT/Frigate <-> Nostr (mesma stack
  # zigbee2mqtt/mosquitto/Frigate já provisionada acima para o dl-conn).
  # A chave secreta Nostr (hex ou nsec bech32 — keystore.Load decodifica os
  # dois, ver cli/internal/keystore/keystore.go) precisa existir em
  # secrets/secrets.yaml sob a chave `nostr.dl-home-control` antes do
  # rebuild (`sops secrets/secrets.yaml` neste repo).
  sops.secrets."nostr/dl-home-control" = {
    owner = "dl-home-control";
    group = "dl-home-control";
  };

  # A TUI do daemon abre com `dl-home-control-tui` (wrapper instalado pelo
  # módulo): ela se liga ao serviço **já em execução** pelo socket de controle
  # local, em vez de subir um segundo daemon. Rodar `cli tui` sem `--attach`
  # com o serviço no ar falha de propósito — seriam duas assinaturas Nostr da
  # mesma pubkey, dois clientes MQTT e dois escritores do acl.json.
  services.dl-home-control = {
    enable = true;
    settings = {
      key_path = config.sops.secrets."nostr/dl-home-control".path;
      mqtt_broker = "tcp://10.1.1.8:1883"; # mosquitto (container zigbee2mqtt, allow_anonymous)
      frigate_url = "http://10.0.66.1:5000";
      camera_tunnel_enabled = true;
    };
  };

  # dl_bestfin — relay Nostr local (strfry) para sync do household na rede
  # local, em vez de depender só dos relays públicos padrão do app. Ver
  # modules/servers/nostr-sync-relay.nix e
  # modules/servers/README-nostr-sync-relay.md para o processo completo.
  #
  # authorizedPubkeys precisa ser preenchido antes do rebuild (o módulo
  # falha a assertion enquanto estiver vazio): abra o app, vá em
  # Sincronização > Identidade, toque na chave (parcialmente exibida) para
  # copiar o hex completo (64 chars) e cole abaixo.
  services.nostrSyncRelay = {
    enable = true;
    authorizedPubkeys = [
      "16719fcbae835e9c27d1c03ae517d07833e89190219f23e8da79f3c417ca7ace"
      # "cole aqui o hex de 64 chars copiado em Sincronização > Identidade"
    ];
  };

  users.users.lluz.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGEuQb+luFJEkBjPJxhQe27+Uo63aVFJs5sQi/N+bgmw lluz@nixos"
  ];

  users.users.dl-conn = {
    isSystemUser = true;
    group = "dl-conn";
    home = "/var/lib/dl-conn";
    createHome = true;
  };
  users.groups.dl-conn = {};
}