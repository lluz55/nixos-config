{ pkgs, unstable, config, ... }:


let
  unstable_pkgs = with unstable; [
    # dev 
    rustc
    cargo
    rust-analyzer

    # Terminal
    zellij
  ];
in
{

  programs.home-manager.enable = true;
  dconf.settings = {
    "org/gnome/desktop/peripherals/keyboard" = {
      numlock-state = true;
      remember-numlock-state = true;
    };
  };
  home.packages = with pkgs; [

    # Terminal
    eza
    fd
    git
    wget
    neovim
    ripgrep
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
    gh

    # TODO: DELETE AFTER INSTALL NEOVIM AS NIX PACKAGE
    cmake
    gnumake
    nodejs
    gcc

  ] ++ unstable_pkgs;
}


# dev
# nodejs
# cmake
# gcc
