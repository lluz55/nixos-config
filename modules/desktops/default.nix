{ lib, ... }:
with lib;
{
  imports = [
    ./gnome.nix
  ];
  options = {
    wayland.enable = mkOption {
      type = types.bool;
      default = false;
      description = mdDoc "Enables the wayland configuration";
    };
    x11.enable = mkOption {
      type = types.bool;
      default = false;
      description = mdDoc "Enables the x11 configuration";
    };
  };
}