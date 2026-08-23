{ lib, ... }:
with lib; {
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
  };
}
