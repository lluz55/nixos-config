{ lib, config, ... }:
with lib;{
  config = mkIf config.useDE
    {
      programs.dconf.enable = true;
      services = {
        xserver = {
          enable = true;
          displayManager.gdm.enable = true;
          desktopManager.gnome.enable = true;
        };
      };
    };
}
