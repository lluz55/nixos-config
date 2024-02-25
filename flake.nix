{
  description = "Pers system flake";
  # nixConfig = {
  #   extra-substituters = [
  #     "https://nix-community.cachix.org"
  #   ];
  #   extra-trusted-public-keys = [
  #     "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
  #   ];
  # };
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixvim = {
      url = "github:nix-community/nixvim/nixos-23.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };  
    home-manager = {
      url = "github:nix-community/home-manager/release-23.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    vscode-server = {
      url = "github:nix-community/nixos-vscode-server";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    nix-direnv = {
      url = "github:nix-community/nix-direnv";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    neovim-flake = {
      url = "github:NotAShelf/neovim-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-ld = {
      url = "github:Mic92/nix-ld";
      # this line assume that you also have nixpkgs as an input
      inputs.nixpkgs.follows = "nixpkgs";
    };
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
    hyprland = {
      url = "github:hyprwm/Hyprland/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprland-nix.url = "github:spikespaz/hyprland-nix";    # hyprland-git.url = "github:hyprwm/hyprland/master";
    hyprland-xdph-git.url = "github:hyprwm/xdg-desktop-portal-hyprland";
    hyprland-protocols-git.url = "github:hyprwm/xdg-desktop-portal-hyprland";
    hypr-contrib.url = "github:hyprwm/contrib";
    hyprpicker.url = "github:hyprwm/hyprpicker";
    
  };

  outputs =
    inputs @ { nixpkgs
    , nixpkgs-unstable
    , home-manager
    , flake-parts
    , nix-direnv
    , neovim-flake
    , nix-ld
    , ...
    }:
    let
      inherit (users) masterUser;
      inherit (users) karolayne;
      users = import ./users.nix;
      secrets = import (builtins.fetchGit {
        url = "git+ssh://git@github.com/lluz55/secrets.git";
      });
      #secrets = import ./secrets/default.nix;
      system = "x86_64-linux";

      unstable = import nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      };
      inherit (nixpkgs) lib;
      overlays = [
          inputs.neovim-nightly-overlay.overlay
        ];
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      mkSystem = name: cfg:
        let
          masterUsername = masterUser.name;
          additionalUserExists = (cfg.additionalUser or null) != null; # Variable must be boolean
          additionalUsername = cfg.additionalUser.name;
        in
        with lib;
        nixosSystem
          {
            inherit system;
            specialArgs =
              {
                inherit inputs unstable masterUser secrets nix-direnv;
              }
              // attrsets.optionalAttrs additionalUserExists { inherit (cfg) additionalUser; };
            modules =
              [
                ./modules
                ./hosts/configuration.nix
                ./hosts/${name}
                masterUser.user
                home-manager.nixosModules.home-manager
                nix-ld.nixosModules.nix-ld
                ({
                  nixpkgs.overlays = overlays;
                })
                {
                  home-manager = {
                    useGlobalPkgs = true;
                    useUserPackages = true;
                    extraSpecialArgs = { inherit pkgs unstable masterUser nix-direnv inputs; };
                    users =
                      {
                        # Load HM configuration for main user
                        "${masterUsername}".imports = [ ./home/${masterUsername}.nix ];
                      }
                      // attrsets.optionalAttrs additionalUserExists {
                        # Load HM configuration for additional user
                        "${additionalUsername}".imports = [ ./home/${additionalUsername}.nix ];
                      };
                  };
                }
              ]
              # In case additional modules was passed
              ++ (cfg.modules or [ ])
              # Details from additional user
              ++ (
                if additionalUserExists
                then [ cfg.additionalUser.user ]
                else [ ]
              );
          };
      # All hosts
      hosts = {
        n100 = { };
        b450 = { };
        gl62m = {
          # TODO: Maybe convert to a List
          additionalUser = karolayne;
        };
      };
    in
    flake-parts.lib.mkFlake { inherit inputs; }
      {
        systems = [ "x86_64-linux" ];
        flake = {
          templates = {
            flutter = {
              path = ./templates/flutter;
              description = "nix flake new -t github:lluz55/nixos-config#flutter <directory>";
            };
            zig = {
              path = ./templates/zig;
              description = "nix flake new -t github:lluz55/nixos-config#zig <directory>";
            };
            bevy = {
              path = ./templates/bevy;
              description = "nix flake new -t github:lluz55/nixos-config#bevy <directory>";
            };
          };
          packages.${system}.neovim = neovim-flake.packages.${system}.maximal;
          nixosConfigurations = lib.mapAttrs mkSystem hosts;
        };
      };
}
