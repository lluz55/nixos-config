{ unstable, config, lib, ... }: 
with lib;{
  config = mkIf config.hyprland.enable {
    programs.waybar = {
      enable = true;
    };
    programs.waybar.package = unstable.waybar.overrideAttrs (oa: {
      mesonFlags = (oa.mesonFlags or [ ]) ++ [ "-Dexperimental=true" ];
    });
  };
}
