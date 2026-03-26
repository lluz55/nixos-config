{ config, lib, pkgs, ... }:
let
  cfg = config.cameraRouter;
in
with lib; {
  config = mkIf cfg.enable {
    networking = {
      firewall.enable = false;
      # Não desabilitar wireless.enable para não quebrar o NetworkManager
      networkmanager.enable = true;
      networkmanager.dns = "dnsmasq";
      networkmanager.unmanaged = [ "interface-name:${cfg.apInterface}" ];
      useNetworkd = false;

      interfaces.${cfg.apInterface}.ipv4.addresses = [
        {
          address = cfg.apAddress;
          prefixLength = cfg.prefixLength;
        }
      ];

      networkmanager.ensureProfiles.profiles = {
        camera-uplink = {
          connection = {
            id = "camera-uplink";
            type = "wifi";
            autoconnect = true;
            "autoconnect-priority" = 100;
            "interface-name" = cfg.uplinkInterface;
          };
          wifi = {
            mode = "infrastructure";
            ssid = cfg.uplinkSsid;
          };
          "wifi-security" = {
            auth-alg = "open";
            key-mgmt = "wpa-psk";
            psk = cfg.uplinkPsk;
          };
          ipv4 = {
            method = "auto";
            dns-search = "";
          };
          ipv6 = {
            method = "auto";
            addr-gen-mode = "stable-privacy";
            dns-search = "";
          };
        };
      };
    };

    services.resolved.enable = lib.mkForce false;
  };
}
