{ pkgs, config, lib, unstable, inputs, ... }:
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
  codegraph-pkg = pkgs.callPackage ../../pkgs/codegraph/package.nix { };
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
  hound-mcp-pkg = pkgs.callPackage ../../pkgs/hound-mcp/package.nix { };
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
    managed_ids = {"hermes"}
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
in
with lib;{
  imports = [
    ./hardware-configuration.nix
    ./router
    inputs.vscode-server.nixosModules.default
    inputs.dl-conn.nixosModules.default
    inputs.hermes-agent.nixosModules.default
    inputs.dl-home-control.nixosModules.default
    ../../pkgs/9router/module.nix
    ../../pkgs/dsh/module.nix
    ../../pkgs/pi-web/module.nix
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

  # Hermes Agent — gateway e dashboard declarativos pelo módulo NixOS
  # oficial. O dashboard fica somente no loopback: o dl_conn é a única
  # entrada remota e já aplica autenticação/autorização Nostr antes do proxy.
  # Hermes suporta prefixos de reverse proxy, portanto /hermes funciona sem
  # bind público e sem abrir a porta 9119 no firewall.
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
      # aparecem no seletor do dashboard e no `/model`, sem duplicar uma
      # lista estática no Nix. O 9router local não exige chave.
      providers."9router" = {
        name = "9Router local";
        api = "http://127.0.0.1:20128/v1";
        transport = "openai_chat";
        discover_models = true;
      };
      model = {
        provider = "9router";
        base_url = "http://127.0.0.1:20128/v1";
        api_mode = "chat_completions";
      };
    };
    extraPackages = with pkgs; [ bash coreutils git ripgrep nodejs_22 ];
  };

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
    opencode
    pi-coding-agent
    config.services.pi-web.package

    config.services.dl-conn.package
  ] ++ [ codegraph-pkg hound-mcp-pkg ];

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
  # explicitamente gerenciados pelo script (Hermes), preservando npubs e
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