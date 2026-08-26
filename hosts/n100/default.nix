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
  # sops.secrets."nostr/dl-conn-key" = {
  #   owner = "dl-conn";
  #   group = "dl-conn";
  # };

  # services.dl-conn = {
  #   enable = true;
  #   configFile = "/etc/dl-conn/config.yaml";
  #   secretFile = config.sops.secrets."nostr/dl-conn-key".path;
  # };

  # users.users.dl-conn = {
  #   isSystemUser = true;
  #   group = "dl-conn";
  #   home = "/var/lib/dl-conn";
  #   createHome = true;
  # };
  # users.groups.dl-conn = {};
}
