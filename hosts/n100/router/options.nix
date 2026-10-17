{ lib, ... }:
with lib;
{
  options = {
    # Interfaces
    WAN = mkOption {
      type = types.str;
      default = "enp1s0";
    };
    LAN0 = mkOption {
      type = types.str;
      default = "enp2s0";
    };
    LAN1 = mkOption {
      type = types.str;
      default = "enp3s0";
    };
    LAN2 = mkOption {
      type = types.str;
      default = "enp4s0";
    };
    WLAN = mkOption {
      type = types.str;
      default = "wlp0s20f0u7";
      description = "Interface sem fio do dongle USB RTL8822BU para modo AP";
    };
  };
}
