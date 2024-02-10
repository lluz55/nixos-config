{ config, masterUser, lib, secrets, ... }:
let
  frigate_secret = secrets.hass.frigate;
  frigate_conf = "/home/${masterUser.name}/.nixos-config/modules/home-automation/frigate";
  frigate_media = "/home/${masterUser.name}/.frigate";
  frigate_usb = "/dev/bus/usb/002/002";
  mqtt_secret = secrets.hass.mqtt;

  containers = import ../../../utils/containers.nix { inherit masterUser; };
  devices = [
    frigate_conf
    frigate_media
    frigate_usb
    "/dev/dri/renderD128"
  ];
  allowedDevices = containers.mkAllowedDevices { inherit devices; };
  bindMounts = containers.mkBindMounts { devicesList = devices; };
in
with lib;
{
  config = mkIf (config.frigate.enable && config.hass.enable) {
    boot.kernel.sysctl."kernel.perf_event_paranoid" = -1;
    systemd.tmpfiles.rules = [
      "d /home/${masterUser.name}/.frigate 0770 ${masterUser.name} users -"
    ];
    containers.homeAuto = {
      inherit allowedDevices;
      inherit bindMounts;

      config = { ... }: {
        boot.isContainer = true;
        networking = {
          firewall = {
            enable = true;
            allowedTCPPorts = [ 5000 8554 8555 ];
            allowedUDPPorts = [ 8555 ];
          };
        };

        system.stateVersion = "23.11";
        virtualisation.oci-containers.containers = {
          frigate = {
            image = "ghcr.io/blakeblackshear/frigate:stable";
            extraOptions = [
              "--shm-size=128mb"
              "--network=host"
              "--device=${frigate_usb}:/dev/bus/usb"
              "--device=/dev/dri/renderD128:/dev/dri/renderD128"
              "--privileged"
              "--mount=type=tmpfs,target=/tmp/cache,tmpfs-size=1000000000"
              "--cap-add=CAP_PERFMON"
            ];
            volumes = [
              "/etc/localtime:/etc/localtime:ro"
              "${frigate_conf}:/config"
              "${frigate_media}:/media/frigate"
            ];
            environment = {
              FRIGATE_PASSWORD = frigate_secret;
              FRIGATE_MQTT_PASSWORD = mqtt_secret;
            };
            ports = [
              "5000:5000"
              "8554:8554"
              "8555:8555/tcp"
            ];
          };

        };
      };
    };
  };
}
