{ config, lib, ... }:
let
  cfg = config.cameraRouter;
in
with lib; {
  options.cameraRouter = {
    enable = mkEnableOption "Tuya camera provisioning network";

    mode = mkOption {
      type = types.enum [ "provisioning" "offline" ];
      default = "provisioning";
      description = mdDoc "Controls whether the camera AP forwards traffic to the Internet.";
    };

    uplinkInterface = mkOption {
      type = types.str;
      default = "wlp3s0";
      description = mdDoc "Wi-Fi interface that connects the laptop to the Internet.";
    };

    apInterface = mkOption {
      type = types.str;
      default = "wlp4s0f3u2";
      description = mdDoc "Wi-Fi interface that exposes the camera AP.";
    };

    uplinkSsid = mkOption {
      type = types.str;
      default = "vl-guests";
    };

    uplinkPsk = mkOption {
      type = types.str;
      default = "";
    };

    ssid = mkOption {
      type = types.str;
      default = "tuya-cameras";
    };

    passphrase = mkOption {
      type = types.str;
      default = "tuya-provisioning";
    };

    countryCode = mkOption {
      type = types.str;
      default = "BR";
    };

    channel = mkOption {
      type = types.int;
      default = 6;
    };

    apAddress = mkOption {
      type = types.str;
      default = "192.168.250.1";
      description = mdDoc "Gateway address on the camera subnet.";
    };

    subnet = mkOption {
      type = types.str;
      default = "192.168.250.0/24";
      description = mdDoc "Camera subnet used for NAT and firewall rules.";
    };

    prefixLength = mkOption {
      type = types.int;
      default = 24;
    };

    dhcpRangeStart = mkOption {
      type = types.str;
      default = "192.168.250.10";
    };

    dhcpRangeEnd = mkOption {
      type = types.str;
      default = "192.168.250.254";
    };

    dnsServers = mkOption {
      type = types.listOf types.str;
      default = [ "8.8.8.8" "8.8.4.4" "1.1.1.1" ];
      description = mdDoc "DNS servers used by dnsmasq for camera internet access during provisioning.";
    };

    cameras = mkOption {
      type = types.listOf (types.submodule {
        options = {
          name = mkOption {
            type = types.str;
          };
          mac = mkOption {
            type = types.str;
          };
          ip = mkOption {
            type = types.str;
          };
          rtspUrl = mkOption {
            type = types.nullOr types.str;
            default = null;
          };
        };
      });
      default = [ ];
    };
  };
}
