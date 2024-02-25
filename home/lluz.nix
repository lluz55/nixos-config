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
    ../modules/hyprland
    ../modules/waybar
    ../modules/swaylock.nix
  ];

  home.stateVersion = "23.11";
  programs.home-manager.enable = true;

  dconf.settings = mkIf config.gnome.enable {
    "org/gnome/desktop/peripherals/keyboard" = {
      numlock-state = false;
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
      gh

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

      # Emulation - Windows VM
      qemu
      quickgui
      quickemu 
    ]);
}
# dev
# nodejs
# cmake
# gcc

