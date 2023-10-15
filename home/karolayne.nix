{ pkgs, config, ... }: {
  programs.home-manager.enable = true;
  home = {
    packages = with pkgs; [
      chromium
    ];
    stateVersion = "23.05";

    #    homeDirectory = "/home/karolayne";
  };
}
