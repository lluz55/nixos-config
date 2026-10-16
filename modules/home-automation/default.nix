{ pkgs, config, lib, masterUser, ... }:
let
  containers = import ../../utils/containers.nix { inherit masterUser; };

  homeAutoPath = "/home/${masterUser.name}/.nixos-config/modules/home-automation/";
  mosquittoPath = "${homeAutoPath}/mosquitto";
  zigbee2mqttPath = "${homeAutoPath}/zigbee2mqtt";
  mqttEnv = config.sops.secrets."mqtt.env".path;

  zigbeeAllowedDevices = containers.mkAllowedDevices {
    devices = [ zigbeeDongleById ];
  };
  zigbeeBindMounts = containers.mkBindMounts {
    devicesList = [ zigbee2mqttPath mosquittoPath mqttEnv ];
    mountDevices = [
      { hostPath = zigbeeDongleById; }
    ];
  };

  zigbeeDongleById = "/dev/serial/by-id/usb-ITead_Sonoff_Zigbee_3.0_USB_Dongle_Plus_86eda3e37f45ed11bdbac68f0a86e0b4-if00-port0";
in
with lib;
{
  imports = [
    ./frigate
  ];

  options.homeAutomation.zigbee2mqtt.enable = mkEnableOption
    "Zigbee2MQTT and Mosquitto in an isolated NixOS container";

  config = mkIf config.homeAutomation.zigbee2mqtt.enable {
    systemd.tmpfiles.rules = containers.mkCreateNeededFolders [
      homeAutoPath
      mosquittoPath
      zigbee2mqttPath
    ];

    containers.zigbee2mqtt = {
      allowedDevices = zigbeeAllowedDevices;
      bindMounts = zigbeeBindMounts;

      autoStart = true;
      privateNetwork = true;
      hostBridge = "br-cams";
      localAddress = "10.1.1.8/24";

      # Nested Podman needs these syscalls beyond nspawn's default seccomp
      # allowlist. Repeated flags are kept as separate arguments.
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

        services.resolved.enable = true;

        virtualisation.oci-containers.containers."zigbee2mqtt" = {
          image = "docker.io/koenkk/zigbee2mqtt:latest";
          volumes = [
            "${zigbee2mqttPath}:/app/data:rw"
            "/run/udev:/run/udev:ro"
          ];
          extraOptions = [
            "--network=host"
            "--device=${zigbeeDongleById}:/dev/ttyUSB0"
            "--env-file=${mqttEnv}"
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
          environment.ZIGBEE2MQTT_CONFIG_PASSWORD = mqttEnv;
        };
      };
    };
  };
}
