{ lib, config, masterUser, secrets, ... }:
let
  _containers = import ../utils/containers.nix { inherit masterUser; };
  allowedDevices = _containers.mkAllowedDevices { };
  bindMounts = _containers.mkBindMounts { };

  network = secrets.twingate.network;
  access_token = secrets.twingate.access_token;
  refresh_token = secrets.twingate.refresh_token;
in
with lib;
{
  config = mkIf (config.twingate.enable) {
    containers.twingate = {
      inherit allowedDevices;
      inherit bindMounts;

      autoStart = true;
      privateNetwork = true;
      hostBridge = "br-lan";
      localAddress = "192.168.1.99/24";

      # Needed for containers inside HASS container to work properly
      additionalCapabilities = [
        ''all" --system-call-filter="add_key keyctl bpf" --capability="all''
      ];

      config = { ... }: {
        boot.isContainer = true;
        system.stateVersion = "23.11";

        environment.systemPackages = with pkgs; [
        ];

        networking = {
          firewall.enable = true;
          firewall.allowedTCPPorts = [ 8123 8080 1883 ];
          firewall.allowedUDPPorts = [ 1883 ];
          useHostResolvConf = mkForce false;
          defaultGateway = "192.168.1.1";
          nameservers = [ "1.1.1.1" "8.8.8.8" ];
        };

        services = {
          resolved.enable = true;
          tailscale.enable = true;
        };

        virtualisation.oci-containers.containers."twingate" = {
          image = "twingate/connector:1";
          environment = {
            TWINGATE_NETWORK = network;
            TWINGATE_ACCESS_TOKEN = access_token;
            TWINGATE_REFRESH_TOKEN = refresh_token;
            TWINGATE_LABEL_HOSTNAME = "`hostname`";
          };
          extraOptions = [
            "--network=host"
            "--privileged"
            "--pull=always"
          ];
        };
      };
    };
  };
}
