{ config, lib, pkgs, ... }:
with lib;
{
  options.profiles.rtl88x2bu.enable = mkEnableOption "TP-Link Archer T3U / RTL88x2BU USB Wi-Fi support";

  config = mkIf config.profiles.rtl88x2bu.enable {
    boot = {
      extraModulePackages = [ config.boot.kernelPackages.rtl88x2bu ];
      kernelModules = [
        "88x2bu"
        "rtw_8812bu"
      ];
      extraModprobeConfig = ''
        blacklist rtw88_8822bu
      '';
    };

    hardware.firmware = [ pkgs.linux-firmware ];
  };
}
