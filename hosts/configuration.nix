{ unstable, lib, pkgs, inputs, master_user, ... }:

{
  #imports = ( 
  #   import ../modules/desktops 
  #   ++ import ../modules/editors
  #   ++ import ../modules/hardware
  #   ++ import ../modules/programs
  #   ++ import ../modules/shell 
  # );
  #

  virtualisation.docker = {
    enable = true;
    rootless = {
      enable = true;
      setSocketVariable = true;
    };
  };

  time.timeZone = "America/Recife";
  i18n = {
    defaultLocale = "pt_BR.UTF-8";
    extraLocaleSettings = {
      LC_TIME = "pt_BR.UTF-8";
      LC_MONETARY = "pt_BR.UTF-8";
    };
  };

  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  lib.useDE = true;

  security = {
    polkit.enable = true;
    rtkit.enable = true;
  };

  fonts.packages = with pkgs; [
    font-awesome
    (nerdfonts.override {
      fonts = [
        "JetBrainsMono"
      ];
    })
  ];

  environment = {
    variables = {
      TERMINAL = "${master_user.terminal}";
      EDITOR = "${master_user.editor}";
      VISUAL = "${master_user.editor}";
    };
    systemPackages = with pkgs; [ ];
  };

  programs.fish.enable = true;
  users.defaultUserShell = pkgs.fish;

  nix = {
    settings = {
      auto-optimise-store = true;
      experimental-features = [ "nix-command" "flakes" ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
    package = pkgs.nixVersions.unstable;
    registry.nixpkgs.flake = inputs.nixpkgs;
  };
  nixpkgs.config.allowUnfree = true;

  system.stateVersion = "23.05";

  home-manager.users.${master_user.name} = {
    home.stateVersion = "23.05";
    programs.home-manager.enable = true;
  };
}
