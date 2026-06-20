{ config, lib, pkgs, ... }:
with lib;
{
  options.gnome.enable = mkOption {
    type = types.bool;
    default = false;
    description = mdDoc "Enable gnome within this flake";
  };

  config = mkIf (config.gnome.enable) {
    services = {
      libinput.enable = true;
      xserver = {
        enable = true;
        xkb.layout = "us";
        modules = [ ];
        displayManager.gdm.enable = true;
        desktopManager.gnome.enable = true;
      };
      udev.packages = with pkgs; [
        gnome-settings-daemon
      ];
    };

    environment = {
      systemPackages = with pkgs; [
        adwaita-icon-theme
        dconf-editor
        gnome-tweaks
        wl-clipboard
      ];
      gnome.excludePackages = (with pkgs; [
        gnome-tour
        epiphany
        geary
        gnome-characters
        gnome-contacts
        gnome-initial-setup
        hitori
        iagno
        tali
        yelp
      ]);
    };
  };
}
