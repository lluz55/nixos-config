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

  allowedDevices = containers.mkAllowedDevices { devices = [ zigbeeDongleById ]; };
  bindMounts = containers.mkBindMounts {
    devicesList = [ zigbee2mqttPath mosquittoPath nodeRedPath mqtt_env ];
    mountDevices = [
      { hostPath = homeAutoPath; isReadOnly = false; }
      { hostPath = zigbeeDongleById; }
    ];
  };
in
with lib;
{
  imports = [
    ./caddy.nix
    ./frigate
  ];
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
      inherit allowedDevices;
      inherit bindMounts;

      autoStart = true;
      privateNetwork = true;
      hostBridge = "br-cams";
      localAddress = "10.1.1.10/24";

      # Needed for containers inside HASS container to work properly
      additionalCapabilities = [
        ''all" --system-call-filter="add_key keyctl bpf" --capability="all''
      ];

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
          firewall.allowedTCPPorts = [ 8123 8080 1883 1880 80];
          firewall.allowedUDPPorts = [ 1883 ];
          useHostResolvConf = mkForce false;
          defaultGateway = "10.1.1.1";
          nameservers = [ "1.1.1.1" "8.8.8.8" ];
        };

        services = {
          resolved.enable = true;
          tailscale.enable = true;
        };

        virtualisation.oci-containers.containers."homeassistant" = {
          image = "ghcr.io/home-assistant/home-assistant:2024.9";
          volumes = [
            "/etc/localtime:/etc/localtime:ro"
            "${hassPath}:/config:rw"
          ];
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

        virtualisation.oci-containers.containers."mosquitto" = {
          image = "eclipse-mosquitto";
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

        virtualisation.oci-containers.containers."zigbee2mqtt" = {
          image = "koenkk/zigbee2mqtt:latest";
          volumes = [
            "${zigbee2mqttPath}:/app/data:rw"
            "/run/udev:/run/udev:ro"
          ];
          extraOptions = [
            "--network=host"
            "--device=/dev/serial/by-id/usb-ITead_Sonoff_Zigbee_3.0_USB_Dongle_Plus_86eda3e37f45ed11bdbac68f0a86e0b4-if00-port0:/dev/ttyACM0"
            "--env-file=${mqtt_env}"
          ];
        };
      };
    };
  };
}

