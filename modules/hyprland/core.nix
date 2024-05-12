{ unstable, lib, config, inputs, ... }:
with lib;{
  config = mkIf config.hyprland.enable {
    programs.hyprland = {
      enable = true;
      package = unstable.hyprland;
      portalPackage = unstable.xdg-desktop-portal-hyprland;
      xwayland.enable = true;
    };
    xdg.portal = {
      enable = true;
      wlr.enable = true;
      xdgOpenUsePortal = true;
      extraPortals = [
        unstable.xdg-desktop-portal-hyprland
      ];
    };

    environment.systemPackages = (with unstable; [
      # swww
      swaybg
      swaylock
      # inputs.hypr-contrib.packages.${unstable.system}.grimblast
      hyprpicker
      wofi
      grim
      slurp
      wl-clipboard
      # cliphist
      wf-recorder
      glib
      python3
      # pipx
      wlogout
      wttrbar

      # wayland
      # hyprland
      #(inputs.hyprland.packages."x86_64-linux".hyprland.override {
      #  # enableNvidiaPatches = true;
      #})

      playerctl
      acpi
      brightnessctl
    ]);
  };
}
