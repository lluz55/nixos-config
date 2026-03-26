{ 
  config
  ,masterUser
  ,lib
  ,...
}:
let
  frigate_conf = "/home/${masterUser.name}/.nixos-config/modules/home-automation/frigate";
  frigate_media = "/home/${masterUser.name}/.frigate";
in
with lib;
{
  options.frigate.enable = mkOption {
    type = types.bool;
    default = false;
    description = mdDoc "Enable Frigate";
  };

  config = mkIf (config.frigate.enable) {
    boot.kernel.sysctl."kernel.perf_event_paranoid" = -1;
    systemd.tmpfiles.rules = [
      "d /home/${masterUser.name}/.frigate 0770 ${masterUser.name} users -"
    ];

    virtualisation.oci-containers.containers = {
      frigate = {
        image = "ghcr.io/blakeblackshear/frigate:0.17.0";
        extraOptions = [
          "--shm-size=512mb"
          "--network=host"
          "--device=/dev/bus/usb:/dev/bus/usb"
          "--device=/dev/dri/renderD128:/dev/dri/renderD128"
          "--privileged"
          "--mount=type=tmpfs,target=/tmp/cache,tmpfs-size=1000000000"
          "--cap-add=ALL"
          "--env-file=${config.sops.secrets."frigate.env".path}"
        ];
        volumes = [
          "/etc/localtime:/etc/localtime:ro"
          "${frigate_conf}:/config"
          "${frigate_media}:/media/frigate"
        ];
        environment = {
          TZ = "America/Recife";
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
