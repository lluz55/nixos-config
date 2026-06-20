{
  masterUser = {
    name = "lluz";
    terminal = "kitty";
    editor = "hx";
    wallpaper = "./wallpapers/landscape.png";
    is_router = true;
    user = { config, ... }: {
      users.users.lluz = {
        isNormalUser = true;
        hashedPasswordFile = config.sops.secrets."passwords/lluz".path;
        extraGroups = [
          "audio"
          "camera"
          "networkmanager"
          "video"
          "wheel"
          "docker"
        ];
      };
    };
  };
  karolayne = {
    name = "karolayne";
    user = { config, ... }: {
      users.users.karolayne = {
        isNormalUser = true;
        hashedPasswordFile = config.sops.secrets."passwords/karolayne".path;
        extraGroups = [ "audio" "camera" "video" ];
      };
    };
  };
}
