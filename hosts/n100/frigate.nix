{ config, nixpkgs, master_user, ... }: {

  virtualisation.oci-containers.containers = {
    frigate = {
      image = "ghcr.io/blakeblackshear/frigate:stable";
      extraOptions = [
        "--shm-size=64mb"
        "--network=host"
      ];
      volumes = [
        "/etc/localtime:/etc/localtime:ro"
        "/home/${master_user.name}/.nixos-config/modules/frigate:/config:ro"
      ];
      ports = [
        "5000:5000"
        "8554:8554"
        "8555:8555/tcp"
      ];
    };
  };

  #containers.frigate = {
  #  autoStart = true;
  #  privateNetwork = true;
  #  hostBridge = "br-cams";
  #  localAddress = "10.1.1.9/24";
  #  system.stateVersion = "23.11";
  #  config = {
  #    networking.firewall.allowedTCPPorts = [ 80 5000 8554 8555 ];
  #    services.frigate = {
  #      enable = true;
  #      hostname = "localhost";
  #      settings = {
  #        mqtt.enabled = false;

  #        cameras.frente_esq = {
  #          ffmpeg = {
  #            #input_args = "-fflags nobuffer -strict experimental -fflags +genpts+discardcorrupt -r 10 -use_wallclock_as_timestamps 1";
  #            inputs = [{
  #              path = "rtsp://10.1.1.12:554/user=admin&password=Luke123luz_&channel=1&stream=1.sdp";
  #              roles = [ ];
  #            }];
  #          };
  #        };

  #        record.enabled = false;
  #      };
  #    };
  #  };
  #};
}
