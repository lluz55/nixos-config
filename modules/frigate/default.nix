{ config, master-user, lib, secrets, ... }:
let
  frigate = secrets.hass.frigate;
in
with lib;
{
  config = mkIf (config.frigate.enable) {
    systemd.tmpfiles.rules = [
      "d /home/${master-user.name}/.frigate 0770 ${master-user.name} users -"
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
        ];
        volumes = [
          "/etc/localtime:/etc/localtime:ro"
          "/home/${master-user.name}/.nixos-config/modules/frigate:/config"
          "/home/${master-user.name}/.frigate:/media/frigate"
        ];
        environment = { FRIGATE_PASSWORD = frigate; };
        ports = [
          "5000:5000"
          "8554:8554"
          "8555:8555/tcp"
        ];
      };
    };
  };
}
