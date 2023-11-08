{ lib, ... }:
with lib;{
  options = {
    useDE = mkOption {
      type = types.bool;
      default = true;
      description = mkDoc ''
        Use Desktop Enviroment
      '';
    };
    wayland = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = mdDoc ''
          Enables the wayland configuration
            > Gets enabled when using a wayland wm
        '';
      };
    };
    x11 = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = mdDoc ''
          Enables the x11 configuration
            > Gets enabled when using a x11 wm
        '';
      };
    };
  };
}
