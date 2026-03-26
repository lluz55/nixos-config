{ config, ... }:
{
  boot = {
    extraModulePackages = [ config.boot.kernelPackages.rtl88x2bu ];
    kernelModules = [ "88x2bu" ];
    extraModprobeConfig = ''
      blacklist rtw88_8822bu
    '';
  };
}
