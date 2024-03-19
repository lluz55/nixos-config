{ unstable, inputs, config, lib, ... }:
with lib; {
  imports = [ inputs.hyprland-nix.homeManagerModules.default ];
  #caches.extraCaches = [{
  #  url = "https://hyprland.cachix.org";
  #  key = "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc=";
  #}];

  config = mkIf config.hyprland.enable {
    home = {
      sessionVariables = {
        EDITOR = "hx";
        BROWSER = "vivaldi";
        TERMINAL = "kitty";
        GBM_BACKEND = "nvidia-drm";
        __GLX_VENDOR_LIBRARY_NAME = "nvidia";
        LIBVA_DRIVER_NAME = "nvidia"; # hardware acceleration
        __GL_VRR_ALLOWED = "1";
        WLR_NO_HARDWARE_CURSORS = "1";
        WLR_RENDERER_ALLOW_SOFTWARE = "1";
        CLUTTER_BACKEND = "wayland";
        WLR_RENDERER = "vulkan";

        XDG_CURRENT_DESKTOP = "Hyprland";
        XDG_SESSION_DESKTOP = "Hyprland";
        XDG_SESSION_TYPE = "wayland";
      };

      packages = with unstable; [
        # swww
        swaybg
        inputs.hypr-contrib.packages.${unstable.system}.grimblast
        hyprpicker
        wofi
        grim
        slurp
        wl-clipboard
        # cliphist
        wf-recorder
        glib
        wayland
        hyprland
        (inputs.hyprland.packages."x86_64-linux".hyprland.override {
          enableNvidiaPatches = true;
        })

        playerctl
        acpi
        brightnessctl
      ];
    };
    systemd.user.targets.hyprland-session.Unit.Wants = [ "xdg-desktop-autostart.target" ];
    wayland.windowManager.hyprland = {
      enable = true;
      reloadConfig = true;
      # systemIntegration = true;
      # nvidiaPatches = true;
      xwayland = {
        enable = true;
        # hidpi = true;
      };
      # enableNvidiaPatches = true;
      # enableNvidiaPatches = true;
      # systemd.enable = true;
    };
  };
}
