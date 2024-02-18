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

    systemd.user.services.fix_frigate = {
      script = ''
        ${pkgs.ripgrep}/bin/rg --passthru '002/003' -N -r '002/002' ~/.nixos-config/modules/home-automation/frigate/default.nix > ~/.frigate.tmp && \
        mv tmp ~/.nixos-config/modules/home-automation/frigate/default.nix \
        sudo ${pkgs.nixos-rebuild}/bin/nixos-rebuild test --impure --flake ~/.nixos-config#n100 && \
        ${pkgs.ripgrep}/bin/rg --passthru '002/002' -N -r '002/003' ~/.nixos-config/modules/home-automation/frigate/default.nix > ~/.frigate.tmp && \
        mv tmp ~/.nixos-config/modules/home-automation/frigate/default.nix \
        sudo ${pkgs.nixos-rebuild}/bin/nixos-rebuild test --impure --flake ~/.nixos-config#n100
      '';
      wantedBy = ["multi-user.target"];
      standardOutput = "tty";
      standardError= "tty";
      after = "container@frigate.service";
    };

    boot.kernel.sysctl."kernel.perf_event_paranoid" = -1;
    systemd.tmpfiles.rules = [
      "d /home/${masterUser.name}/.frigate 0770 ${masterUser.name} users -"
    ];

    containers.frigate = {
      inherit allowedDevices;
      inherit bindMounts;

      autoStart = true;
      privateNetwork = true;
      hostBridge = "br-cams";
      localAddress = "10.1.1.9/24";

      # Needed for containers inside HASS container to work properly
      additionalCapabilities = [
        ''all" --system-call-filter="add_key keyctl bpf" --capability="all''
     ];

      config = { ... }: {
        boot. isContainer = true;
        system.stateVersion = "23.11";

        environment.systemPackages = with pkgs; [
        ];

        networking = {
          firewall.enable = true;
            allowedTCPPorts = [ 5000 8554 8555 ];
            allowedUDPPorts = [ 8555 ];
          useHostResolvConf = mkForce false;
          defaultGateway = "10.1.1.1";
          # nameservers = [ "1.1.1.1" "8.8.8.8" ];
        };

        services = {
          resolved.enable = true;
          tailscale.enable = true;
        };

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
