{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
{
  services.hostapd = {
    enable = true;
    radios.${config.WLAN} = {
      band = "2g";
      channel = 6;
      countryCode = "BR";
      wifi4 = {
        enable = true;
        capabilities = [
          "HT40+"
          "SHORT-GI-20"
          "SHORT-GI-40"
        ];
      };
      wifi5.enable = false;
      networks.${config.WLAN} = {
        ssid = "N100-WiFi";
        authentication = {
          mode = "wpa2-sha256";
          wpaPasswordFile = config.sops.secrets."wifi/psk".path;
        };
        settings = {
          bridge = "br-lan";
        };
      };
    };
  };

  # Garante que o systemd-networkd não tente atribuir IP à interface física do Wi-Fi,
  # mantendo-a como unmanaged para o hostapd inseri-la no bridge br-lan
  systemd.network.networks."30-${config.WLAN}" = {
    matchConfig.Name = config.WLAN;
    linkConfig = {
      Unmanaged = true;
      RequiredForOnline = "no";
    };
  };

  # Garante que a bridge br-lan esteja criada pelo networkd antes do hostapd tentar conectar a interface
  systemd.services.hostapd = {
    after = [ "systemd-networkd.service" ];
    wants = [ "systemd-networkd.service" ];
  };
}
