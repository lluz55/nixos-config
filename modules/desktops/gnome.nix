{ config, lib, pkgs, masterUser, ... }:
let
  colors = import ../theming/colors.nix;
in
with lib;
{
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
        gnome.gnome-settings-daemon
      ];
    };

    environment = {
      systemPackages = with pkgs; [
        gnome.adwaita-icon-theme
        gnome.dconf-editor
        gnome.gnome-tweaks
        wl-clipboard
      ];
      gnome.excludePackages = (with pkgs; [
        gnome-tour
      ]) ++ (with pkgs.gnome; [
        atomix
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

    home-manager.users.lluz = {
      dconf.settings = {
        "orgs/gnome/shell" = {
          disable-user-extension = false;
          enabled-extension = [
          ];
        };
        "org/gnome/shell" = {
          favorite-apps = [
            "firefox.desktop"
            "kitty.desktop"
            "org.gnome.Nautilus.desktop"
          ];
        };
        "org/gnome/desktop/interface" = {
          color-scheme = "prefer-dark";
          enable-hot-corners = false;
          clock-show-weekday = true;
        };
        "org/gnome/desktop/peripherals/touchpad" = {
          tap-to-click = true;
          two-finger-scrolling-enable = true;
        };
        "org/gnome/desktop/wm/keybindings" = {
          switch-windows = [ "<Alt>Tab" ];
          switch-windows-backward = [ "<Shift><Alt>Tab" ];
        };
        #"org/gnome/desktop/background" = {
        #  picture-uri = "${var.wallpaper}";
        #};
        #"org/gnome/desktop/wm/keybindings" = {
        #  maximize = [ "<Alt>Plus" ];
        #  unmaximize = [ "<Alt>Minus" ];
        #  switch-to-workspace-left = [ "<Alt>Left" ];
        #  switch-to-workspace-right = [ "<Alt>Right" ];
        #  switch-to-workspace-1 = [ "<Alt>1" ];
        #  switch-to-workspace-2 = [ "<Alt>2" ];
        #  switch-to-workspace-3 = [ "<Alt>3" ];
        #  switch-to-workspace-4 = [ "<Alt>4" ];
        #  switch-to-workspace-5 = [ "<Alt>5" ];
        #  move-to-workspace-left = [ "<Shift><Alt>Left" ];
        #  move-to-workspace-right = [ "<Shift><Alt>Right" ];
        #  move-to-workspace-1 = [ "<Shift><Alt>1" ];
        #  move-to-workspace-2 = [ "<Shift><Alt>2" ];
        #  move-to-workspace-3 = [ "<Shift><Alt>3" ];
        #  move-to-workspace-4 = [ "<Shift><Alt>4" ];
        #  move-to-workspace-5 = [ "<Shift><Alt>5" ];
        #  move-to-monitor-left = [ "<Super><Alt>Left" ];
        #  move-to-monitor-right = [ "<Super><Alt>Right" ];
        #  close = [ "<Alt>q" "<Alt>F4" ];
        #  toggle-fullscreen = [ "<Super>f" ];
        #};
        "org/gnome/settings-daemon/plugins/media-keys" = {
          custom-keybindings = [
            "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
          ];
        };
        "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
          binding = "<Ctrl><Alt>T";
          command = "kitty";
          name = "open-terminal";
        };
      };

      home.packages = with pkgs; [
        gnomeExtensions.pop-shell
      ];
    };
  };
}
