{ config, masterUser, lib, secrets, ... }:
let
  frigate = secrets.hass.frigate;
  mqtt = secrets.hass.mqtt;
in
with lib;
{
  config = mkIf (config.frigate.enable) {
    systemd.tmpfiles.rules = [
      "d /home/${masterUser.name}/.frigate 0770 ${masterUser.name} users -"
    ];

    virtualisation.oci-containers.containers = {
      frigate = {
        image = "ghcr.io/blakeblackshear/frigate:stable";
        extraOptions = [
          "--shm-size=64mb"
          "--network=host"
          "--device=/dev/bus/usb:/dev/bus/usb"
          "--privileged"
          "--mount=type=tmpfs,target=/tmp/cache,tmpfs-size=1000000000"
          "--cap-add=CAP_PERFMON"
        ];
        volumes = [
          "/etc/localtime:/etc/localtime:ro"
          "/home/${masterUser.name}/.nixos-config/modules/frigate:/config"
          "/home/${masterUser.name}/.frigate:/media/frigate"
        ];
        environment = {
          FRIGATE_PASSWORD = frigate;
          FRIGATE_MQTT_PASSWORD = mqtt;
        };
        ports = [
          "5000:5000"
          "8554:8554"
          "8555:8555/tcp"
        ];
      };
    };
  };
}
