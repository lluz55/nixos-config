{ lib, config, masterUser, ... }:
# let
#   _containers = import ../utils/containers.nix { inherit masterUser; };
#   bindMounts = _containers.mkBindMounts { devicesList = [ config.sops.secrets."twingate.env".path ]; };
#   allowedDevices = _containers.mkAllowedDevices { devices = [ "/dev/fuse" ]; };

# in
with lib;
{
  config = mkIf (config.twingate.enable) {
    # containers.twingate = {
    #   inherit allowedDevices;
    #   inherit bindMounts;

    #   autoStart = true;
    #   privateNetwork = true;
    #   hostBridge = "br-lan";
    #   localAddress = "192.168.1.99/24";

    #   # Needed for containers inside HASS container to work properly
    #   additionalCapabilities = [
    #     ''all" --system-call-filter="add_key keyctl bpf" --capability="all''
    #   ];

    #   config = { ... }: {
    #     boot.isContainer = true;
    #     system.stateVersion = "23.11";

    #     environment.systemPackages = with pkgs; [];

    #     networking = {
    #       firewall.enable = true;
    #       firewall.allowedTCPPorts = [ 8123 8080 1883 ];
    #       firewall.allowedUDPPorts = [ 1883 ];
    #       useHostResolvConf = mkForce false;
    #       defaultGateway = "192.168.1.1";
    #       nameservers = [ "1.1.1.1" "8.8.8.8" ];
    #     };

    #     services = {
    #       resolved.enable = true;
    #       tailscale.enable = true;
    #     };

        virtualisation.oci-containers.containers."twingate" = {
          image = "twingate/connector:1.70";
          environment = {
            # DNS_SERVER="8.8.8.8,1.1.1.1";
            TWINGATE_LABEL_HOSTNAME = "`hostname`";
          };
          extraOptions = [
            "--network=host"
            "--privileged"
            "--cap-add=ALL"
            "--pull=always"
            "--env-file=${config.sops.secrets."twingate.env".path}"
          ];
        };
      };
#     };
#   };
 }

