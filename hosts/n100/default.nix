{ pkgs, config, lib, unstable, ... }:
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
  ];

  console = {
    font = "Lat2-Terminus16";
    keyMap = "br-abnt2";
  };

  gnome.enable = false;
  hass.enable = true;
  frigate.enable = true;
  vscode-server.enable = true;
  glances.enable = true;
  twingate.enable = true;

  services.tailscale.enable = true;
  programs.mosh.enable = true;

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;
    };
  };

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
    killall
    du-dust
    glances
    htop
    btop
    nmap
    usbutils
  ];

  boot = {
		# Must use 6.7 until find fix for Gasket kernel module
    kernelPackages = pkgs.linuxPackages_6_7;
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
      timeout = 2;
    };
    extraModulePackages = [ gasketPkg ];
    tmp = {
      useTmpfs = true;
      tmpfsSize = "30%";
    };
  };

  programs.light.enable = true;
}
