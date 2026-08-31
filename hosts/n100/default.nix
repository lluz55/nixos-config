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
in
with lib;{
  imports = [
    ./hardware-configuration.nix
    ./router
    inputs.vscode-server.nixosModules.default
    inputs.dl-conn.nixosModules.default
    inputs.dl-home-control.nixosModules.default
  ];

  console = {
    font = "Lat2-Terminus16";
    keyMap = "br-abnt2";
  };

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

    config.services.dl-conn.package
  ];

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
    "C /var/lib/dl-conn/config.yaml 0640 dl-conn dl-conn - ${./dl-conn-config.yaml}"
  ];

  # dl_home_control — daemon ponte MQTT/Frigate <-> Nostr (mesma stack
  # zigbee2mqtt/mosquitto/Frigate já provisionada acima para o dl-conn).
  # A chave secreta Nostr (hex ou nsec bech32 — keystore.Load decodifica os
  # dois, ver cli/internal/keystore/keystore.go) precisa existir em
  # secrets/secrets.yaml sob a chave `nostr.dl_home_control` antes do
  # rebuild (`sops secrets/secrets.yaml` neste repo).
  sops.secrets."nostr/dl_home_control" = {
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
      key_path = config.sops.secrets."nostr/dl_home_control".path;
      mqtt_broker = "tcp://10.1.1.8:1883"; # mosquitto (container zigbee2mqtt, allow_anonymous)
      frigate_url = "http://10.0.66.1:5000";
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
