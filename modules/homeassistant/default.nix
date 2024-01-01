{ pkgs, config, lib, masterUser, secrets, ... }:
let
  hass_path = "/home/${masterUser.name}/.nixos-config/modules/homeassistant";
  mosquitto_path = "${hass_path}/mosquitto";
  hass_config_path = "${hass_path}/config";
  zigbee2mqtt_path = "${hass_path}/zigbee2mqtt";

  mqtt = secrets.hass.mqtt;
in
with lib; {
  config = mkIf (config.hass.enable) {
    # Create files if doens't exist for Docker/Podman
    systemd.tmpfiles.rules = [
      "d ${hass_path} 0770 ${masterUser.name} users -"
      "d ${hass_config_path} 0770 ${masterUser.name} users -"
      "d ${mosquitto_path} 0770 ${masterUser.name} users -"
      "d ${zigbee2mqtt_path} 0770 ${masterUser.name} users -"
    ];

    containers.hass = {
      autoStart = true;
      privateNetwork = true;
      hostBridge = "br-cams";
      localAddress = "10.1.1.10/24";

      bindMounts = {
        # Needed for containers inside HASS container to have access to host files 
        "/var/hass" = {
          hostPath = "${hass_path}";
          isReadOnly = false;
        };
        # Needed for containers inside HASS container to work properly
        "/dev/fuse" = {
          hostPath = "/dev/fuse";
        };
        # Needed for containers inside HASS container to work properly
        "/dev/net/tun" = {
          hostPath = "/dev/net/tun";
        };
        # Needed for zigbee2mqtt
        "/run/udev/" = {
          hostPath = "/run/udev/";
        };
        # Needed for zigbee Coordenator
        "/dev/ttyACM0" = {
          hostPath = "/dev/serial/by-id/usb-ITead_Sonoff_Zigbee_3.0_USB_Dongle_Plus_86eda3e37f45ed11bdbac68f0a86e0b4-if00-port0";
        };
      };
      # Needed for containers inside HASS container to work properly
      additionalCapabilities = [
        ''all" --system-call-filter="add_key keyctl bpf" --capability="all''
      ];
      allowedDevices = [
        # Needed for containers inside HASS container to work properly
        { node = "/dev/fuse"; modifier = "rwm"; }
        # Needed for containers inside HASS container to work properly
        { node = "/dev/mapper/control"; modifier = "rw"; }
        # Needed for containers inside HASS container to work properly
        { node = "/dev/net/tun"; modifier = "rwm"; }
        # Needed for containers inside HASS container to work properly
        { node = "/dev/console"; modifier = "rwm"; }
        # Needed for zigbee Coordenator
        {
          node = "/dev/serial/by-id/usb-ITead_Sonoff_Zigbee_3.0_USB_Dongle_Plus_86eda3e37f45ed11bdbac68f0a86e0b4-if00-port0";
          modifier = "rwm";
        }
      ];

      config = { ... }: {
        boot.isContainer = true;

        environment.systemPackages = with pkgs; [
          # Needed for debug
          netcat
          tcpdump
          tailscale
          nmap
        ];
        system.stateVersion = "23.11";
        networking = {
          firewall.enable = true;
          firewall.allowedTCPPorts = [ 8123 8080 1883 ];
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
          image = "ghcr.io/home-assistant/home-assistant:stable";
          volumes = [
            "/etc/localtime:/etc/localtime:ro"
            "/var/hass/config:/config:rw"
          ];
          extraOptions = [
            "--network=host"
            "--privileged"
          ];
        };

        virtualisation.oci-containers.containers."mosquitto" = {
          image = "eclipse-mosquitto";
          volumes = [
            "/var/hass/mosquitto:/mosquitto:rw"
          ];
          extraOptions = [
            "--network=host"
          ];
          environment = {
            ZIGBEE2MQTT_CONFIG_PASSWORD = mqtt;
          };
        };

        virtualisation.oci-containers.containers."zigbee2mqtt" = {
          image = "koenkk/zigbee2mqtt";
          volumes = [
            "/var/hass/zigbee2mqtt:/app/data:rw"
            "/run/udev:/run/udev:ro"
          ];
          extraOptions = [
            "--network=host"
            "--device=/dev/ttyACM0:/dev/ttyACM0"
          ];
          environment = {
            ZIGBEE2MQTT_CONFIG_PASSWORD = mqtt;
          };
        };
      };
    };
  };
}
