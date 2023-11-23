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

  #nixpkgs.config = {
  #  allowBroken = true;
  #  permittedInsecurePackages = [
  #    "python3.10-tensorflow-2.11.1"
  #    "tensorflow-2.11.1"
  #    "tensorflow-2.11.1-deps.tar.gz"
  #  ];
  #};

  #services.frigate = {
  #  enable = true;

  #  hostname = "localhost";

  #  settings = {
  #    mqtt.enabled = false;

  #    cameras.frente_esq = {
  #      ffmpeg = {
  #        input_args = "-fflags nobuffer -strict experimental -fflags +genpts+discardcorrupt -r 10 -use_wallclock_as_timestamps 1";
  #        inputs = [{
  #          path = "rtsp://10.1.1.12:554/user=admin&password=Luke123luz_&channel=1&stream=0.sdp";
  #          roles = [ ];
  #        }];
  #      };
  #    };

  #    record.enabled = false;
  #  };
  #};

  #systemd.services.video-stream = {
  #  description = "Start a test stream that frigate can capture";
  #  before = [
  #    "frigate.service"
  #  ];
  #  wantedBy = [
  #    "multi-user.target"
  #  ];
  #  serviceConfig = {
  #    DynamicUser = true;
  #    ExecStart = "${lib.getBin pkgs.ffmpeg-headless}/bin/ffmpeg -re -f lavfi -i smptebars=size=800x600:rate=10 -f mpegts -listen 1 http://0.0.0.0:8080";
  #  };
  #};
}
