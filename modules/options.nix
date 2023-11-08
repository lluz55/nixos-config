{ lib, ... }:
with lib;{
  options = {
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
    nvidia = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = mkDoc ''
          Enables nvidia drivers
        '';
      };
    };
    gnome = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = mdDoc ''
          Enable gnome within this flake
        '';
      };
    };
  };
}
