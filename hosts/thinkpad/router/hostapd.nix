{ config, lib, ... }:
let
  cfg = config.cameraRouter;
in
with lib; {
  config = mkIf cfg.enable {
    services.hostapd = {
      enable = true;
      radios.${cfg.apInterface} = {
        countryCode = cfg.countryCode;
        band = "2g";
        channel = cfg.channel;
        networks.${cfg.apInterface} = {
          ssid = cfg.ssid;
          authentication = {
            mode = "wpa2-sha256";
            wpaPassword = cfg.passphrase;
          };
        };
      };
    };

    # hostapd precisa iniciar após NetworkManager para garantir que a interface está disponível
    systemd.services.hostapd.after = [ "NetworkManager.service" ];
    systemd.services.hostapd.wants = [ "NetworkManager.service" ];
  };
}
