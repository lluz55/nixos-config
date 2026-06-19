{ pkgs
, unstable
, lib
, osConfig
, llm-agents
, openai-codex
, ...
}:
with lib;
{
  home.stateVersion = "23.11";
  programs.home-manager.enable = true;

  dconf.settings = mkIf osConfig.gnome.enable {
    "org/gnome/desktop/peripherals/keyboard" = {
      numlock-state = true;
    };

    "org/gnome/shell" = {
      favorite-apps = [
        "firefox.desktop"
        "kitty.desktop"
        "org.gnome.Nautilus.desktop"
      ];
    };
  };

  programs = {
    fish.enable = true;
    direnv = {
      enable = true;
      enableBashIntegration = true; # see note on other shells below
      nix-direnv.enable = true;
    };
  };

  xdg.configFile = {
    "qutebrowser/config.py" = {
      source = ./qutebrowser/config.py;
      force = true;
    };
    "qutebrowser/autoconfig.yml" = {
      source = ./qutebrowser/autoconfig.yml;
      force = true;
    };
    "qutebrowser/quickmarks" = {
      source = ./qutebrowser/quickmarks;
      force = true;
    };
    "qutebrowser/bookmarks/urls" = {
      text = "";
      force = true;
    };
  };

  home.packages = (with unstable; [
    wget
    # Terminal
    eza
    fd
    git
    wget
    kitty
    starship

    # Audio
    pamixer
    playerctl

    # Files
    unzip
    unrar
    zip

    # browser
    firefox
    chromium
    qutebrowser

    # social

    discord
    telegram-desktop

    # dev
    distrobox
    docker
    claude-code
    antigravity
  ]) ++ [
    llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.antigravity-cli
    openai-codex
  ] ++ (with unstable; [

    # TODO: DELETE AFTER INSTALL NEOVIM AS NIX PACKAGE
    cmake
    gnumake
    nodejs
    gcc

    # Terminal
    rustup
    zellij
    nmap
    lazygit
    ripgrep
    nil
    lua-language-server
    broot
    sd
    zoxide
    fastfetch
    bat

    # Emulation - Windows VM
    # qemu     !!! FLUTTER ERROR 19/09
    # quickgui !!! FLUTTER ERROR 19/09
    # quickemu !!! FLUTTER ERROR 19/09
    # https://github.com/NixOS/nixpkgs/issues/341893
  ]);
}
# dev
# nodejs
# cmake
# gcc
