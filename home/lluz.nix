{ pkgs
, unstable
, lib
, config
, ...
}:
with lib;
{
  imports = [
    ../modules/options.nix
  ];

  home.stateVersion = "23.11";
  programs.home-manager.enable = true;

  dconf.settings = mkIf config.gnome.enable {
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

    # social

    discord
    telegram-desktop

    # dev
    distrobox
    docker

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
    neofetch
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

