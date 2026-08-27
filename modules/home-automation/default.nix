{ pkgs, config, lib, masterUser, ... }:
let
  containers = import ../../utils/containers.nix { inherit masterUser; };

  homeAutoPath = "/home/${masterUser.name}/.nixos-config/modules/home-automation/";
  mosquittoPath = "${homeAutoPath}/mosquitto";
  hassPath = "${homeAutoPath}/homeassistant";
  zigbee2mqttPath = "${homeAutoPath}/zigbee2mqtt";
  nodeRedPath = "${homeAutoPath}/node-red";

  zigbeeDongleById = "/dev/serial/by-id/usb-ITead_Sonoff_Zigbee_3.0_USB_Dongle_Plus_86eda3e37f45ed11bdbac68f0a86e0b4-if00-port0";
  mqtt_env = config.sops.secrets."mqtt.env".path;

  homeAutoAllowedDevices = containers.mkAllowedDevices { };
  homeAutoBindMounts = containers.mkBindMounts {
    devicesList = [ nodeRedPath ];
    mountDevices = [
      { hostPath = homeAutoPath; isReadOnly = false; }
    ];
  };

  zigbeeAllowedDevices = containers.mkAllowedDevices { devices = [ zigbeeDongleById ]; };
  zigbeeBindMounts = containers.mkBindMounts {
    devicesList = [ zigbee2mqttPath mosquittoPath mqtt_env ];
    mountDevices = [
      { hostPath = zigbeeDongleById; }
    ];
  };
in
with lib;
{
  imports = [
    ./frigate
  ];

  options.hass.enable = mkOption {
    type = types.bool;
    default = false;
    description = mdDoc "Enable Home Assistant";
  };

  config = mkIf (config.hass.enable) {
    # Create files if doens't exist for Docker/Podman
    systemd.tmpfiles.rules = containers.mkCreateNeededFolders [
      homeAutoPath
      hassPath
      mosquittoPath
      zigbee2mqttPath
      nodeRedPath
    ];

    containers.homeAuto = {
      allowedDevices = homeAutoAllowedDevices;
      bindMounts = homeAutoBindMounts;

      autoStart = true;
      privateNetwork = true;
      hostBridge = "br-cams";
      localAddress = "10.1.1.10/24";

      # Nested Podman (running --privileged OCI containers) needs these
      # syscalls beyond nspawn's default seccomp allowlist. EXTRA_NSPAWN_FLAGS
      # is expanded unquoted at runtime, so each flag must be its own list
      # element (no embedded spaces) or the shell word-splits it; nspawn
      # merges repeated --system-call-filter= occurrences.
      extraFlags = [
        "--system-call-filter=add_key"
        "--system-call-filter=keyctl"
        "--system-call-filter=bpf"
      ];
      additionalCapabilities = [ "all" ];

      config = { ... }: {
        boot. isContainer = true;
        system.stateVersion = "23.11";

        environment.systemPackages = with pkgs; [
          # Needed for debug
          netcat
          tcpdump
          nmap
          arp-scan
        ];

        networking = {
          firewall.enable = true;
          firewall.allowedTCPPorts = [ 8123 1880 80 ];
          useHostResolvConf = mkForce false;
          defaultGateway = "10.1.1.1";
          nameservers = [ "1.1.1.1" "8.8.8.8" ];
        };

        services = {
          resolved.enable = true;
          tailscale.enable = true;
        };

        virtualisation.oci-containers.containers."homeassistant" = {
          image = "ghcr.io/home-assistant/home-assistant:2026.3";
          volumes = [
            "/etc/localtime:/etc/localtime:ro"
            "${hassPath}:/config:rw"
          ];
          environment = {
            PYTHONPATH="/config/deps";
          };
          extraOptions = [
            "--network=host"
            "--privileged"
          ];
        };

        virtualisation.oci-containers.containers."nodered" = {
          image = "nodered/node-red";
          volumes = [
            "${nodeRedPath}:/data"
          ];
          extraOptions = [
            "--network=host"
          ];
          environment = {
            TZ = "America/Brasilia";
          };
        };
      };
    };

    containers.zigbee2mqtt = {
      allowedDevices = zigbeeAllowedDevices;
      bindMounts = zigbeeBindMounts;

      autoStart = true;
      privateNetwork = true;
      hostBridge = "br-cams";
      localAddress = "10.1.1.8/24";

      # See homeAuto above: nested Podman needs these syscalls beyond
      # nspawn's default seccomp allowlist.
      extraFlags = [
        "--system-call-filter=add_key"
        "--system-call-filter=keyctl"
        "--system-call-filter=bpf"
      ];
      additionalCapabilities = [ "all" ];

      config = { ... }: {
        boot.isContainer = true;
        system.stateVersion = "23.11";

        environment.systemPackages = with pkgs; [
          # Needed for debug
          netcat
          tcpdump
          usbutils
        ];

        networking = {
          firewall.enable = true;
          firewall.allowedTCPPorts = [ 8080 1883 ];
          useHostResolvConf = mkForce false;
          defaultGateway = "10.1.1.1";
          nameservers = [ "1.1.1.1" "8.8.8.8" ];
        };

        services = {
          resolved.enable = true;
        };

        virtualisation.oci-containers.containers."zigbee2mqtt" = {
          image = "docker.io/koenkk/zigbee2mqtt:latest";
          volumes = [
            "${zigbee2mqttPath}:/app/data:rw"
            "/run/udev:/run/udev:ro"
          ];
          extraOptions = [
            "--network=host"
            "--device=${zigbeeDongleById}:/dev/ttyUSB0"
            "--env-file=${mqtt_env}"
          ];
        };

        virtualisation.oci-containers.containers."mosquitto" = {
          image = "docker.io/eclipse-mosquitto";
          volumes = [
            "${mosquittoPath}:/mosquitto:rw"
          ];
          extraOptions = [
            "--network=host"
          ];
          environment = {
            ZIGBEE2MQTT_CONFIG_PASSWORD = mqtt_env;
          };
        };
      };
    };
  };
}

