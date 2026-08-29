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
    settings = {
      nostr = {
        relays = [
          "wss://relay.damus.io"
          "wss://nos.lol"
          "wss://relay.nostr.band"
          "wss://relay.primal.net"
          "wss://nostr.mom"
          "wss://relay.snort.social"
          "wss://nostr.oxtr.dev"
          "wss://nostr.land"
        ];
        authorizedNpubs = [
          "npub19eza5qtcr620pufewsnjdvk2c540naaa43nuhzn336myuswzc77sd0jd8z"
          "npub1e247rm7ndy0p9reyhrhtwckkkkxpqpd8ya5m0qa22f7evuacmkwspjxh0y"
        ];
        fallbackNip04 = false;
      };
      tunnel = {
        listenPort = 9099;
        cloudflaredPath = "cloudflared";
        autoStart = true;
        inactivityTimeout = "10m";
      };
      auth = {
        tokenTTL = "120s";
        sessionTTL = "4h";
      };
      services = [
        {
          id = "hass";
          name = "Home Assistant";
          icon = "home";
          prefix = "/hass";
          target = "http://10.1.1.10:8123";
          stripPrefix = true;
          websocket = true;
          # HASS answers 400 to every request while dl_conn is not in its
          # trusted_proxies. Remove once HA has "use_x_forwarded_for: true"
          # + "trusted_proxies: [10.1.1.1]".
          forwardedFor = false;
        }
        {
          id = "frigate";
          name = "Frigate";
          icon = "video";
          prefix = "/frigate";
          target = "http://10.0.66.1:5000";
          stripPrefix = true;
          websocket = false;
          rootPaths = [ "/locales/" ];
        }
        {
          id = "frigate-api";
          name = "Frigate API";
          icon = "video";
          prefix = "/api";
          target = "http://10.0.66.1:5000";
          stripPrefix = false;
          websocket = false;
          hidden = true;
        }
        {
          id = "frigate-ws";
          name = "Frigate WebSocket";
          icon = "video";
          prefix = "/ws";
          target = "http://10.0.66.1:5000";
          stripPrefix = false;
          websocket = true;
          hidden = true;
        }
        {
          id = "zigbee2mqtt";
          name = "Zigbee2MQTT";
          icon = "router";
          prefix = "/zigbee2mqtt";
          target = "http://10.1.1.8:8080";
          stripPrefix = true;
          websocket = true;
        }
      ];
    };
  };

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

  services.dl-home-control = {
    enable = true;
    settings = {
      key_path = config.sops.secrets."nostr/dl_home_control".path;
      mqtt_broker = "tcp://10.1.1.8:1883"; # mosquitto (container zigbee2mqtt, allow_anonymous)
      frigate_url = "http://10.0.66.1:5000";
    };
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
