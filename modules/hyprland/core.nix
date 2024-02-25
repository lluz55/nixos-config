{ unstable, lib, config, ... }:
with lib;{
  config = mkIf config.hyprland.enable {
    programs.hyprland = {
      enable = true;
      package = unstable.hyprland;
      portalPackage = unstable.xdg-desktop-portal-hyprland;
     enableNvidiaPatches = true;
     xwayland.enable = true;
    };
    xdg.portal = {
      enable = true;
      wlr.enable = true;
      xdgOpenUsePortal = true;
      extraPortals = [
        unstable.xdg-desktop-portal-hyprland
        unstable.xdg-desktop-portal-gtk
      ];
    };
     systemd.user.services = {
       xwaylandvideobridge = {
         Unit = {
           Description = "Tool to make it easy to stream wayland windows and screens to existing applications running under Xwayland";
         };

         Service = {
           Type = "simple";
           ExecStart = "${unstable.xwaylandvideobridge}/bin/xwaylandvideobridge";
           Restart = "on-failure";
         };

         Install = {
           WantedBy = ["default.target"];
         };
       };
     };
  };
}
