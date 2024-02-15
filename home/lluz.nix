{
  pkgs,
  unstable,
  lib,
  config,
  ...
}: let
  unstable_pkgs = with unstable; [
    # dev
    rustc
    cargo
    rust-analyzer

    # Terminal
    zellij
  ];
in
  with lib; {
    imports = [
      ../modules/options.nix
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
      #neovim-flake = {
      #  enable = true;
      #  # your settings need to go into the settings attribute set
      #  # most settings are documented in the appendix
      #  settings = {
      #    vim = {
      #      viAlias = false;
      #      vimAlias = true;
      #      theme.enable = true;
      #      languages = {
      #        enableTreesitter = true;
      #        enableLSP = true;
      #        rust = {
      #          enable = true;
      #        };
      #        nix = {
      #          enable = true;
      #        };
      #      };
      #    };
      #  };
      #};
    };

    home.packages = with pkgs;
      [
        # Terminal
        eza
        fd
        git
        wget
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
      ]
      ++ unstable_pkgs;
  }
# dev
# nodejs
# cmake
# gcc

