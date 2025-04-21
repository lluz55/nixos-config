{
  description = "Pers system flake";
  nixConfig = {
    accept-flake-config = true;
    extra-substituters = [
      "https://cosmic.cachix.org/"
      "https://nix-community.cachix.org"
    ];
    extra-trusted-substituters = [
      "https://cosmic.cachix.org/"
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "cosmic.cachix.org-1:Dya9IyXD4xdBehWjrkPv6rtxpmMdRel02smYzA85dPE="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs.follows = "nixos-cosmic/nixpkgs"; # NOTE: change "nixpkgs" to "nixpkgs-stable" to use stable NixOS release
    # nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    #vscode-server = {
    #  url = "github:nix-community/nixos-vscode-server";
    #  inputs.nixpkgs.follows = "nixpkgs";
    #};
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    nix-direnv = {
      url = "github:nix-community/nix-direnv";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    rust-overlay.url = "github:oxalica/rust-overlay";
    nixos-cosmic = {
      url = "github:lilyinstarlight/nixos-cosmic";
      # inputs.nixpkgs.follows = "nixos-cosmic/nixpkgs";
    };
    # zen-browser.url = "github:0xc000022070/zen-browser-flake";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # hyprland-nix.url = "github:spikespaz/hyprland-nix"; # hyprland-git.url = "github:hyprwm/hyprland/master";
    #hyprland-xdph-git.url = "github:hyprwm/xdg-desktop-portal-hyprland";
    #hyprland-protocols-git.url = "github:hyprwm/xdg-desktop-portal-hyprland";
    #hypr-contrib.url = "github:hyprwm/contrib";
    #hyprpicker.url = "github:hyprwm/hyprpicker";

    #nix-ld = {
    #  url = "github:Mic92/nix-ld";
    #  # this line assume that you also have nixpkgs as an input
    #  inputs.nixpkgs.follows = "nixpkgs";
    #};
  };

  outputs = inputs @ {
    nixpkgs,
    nixpkgs-unstable,
    home-manager,
    flake-parts,
    nix-direnv,
    rust-overlay,
    nixos-cosmic,
    # zen-browser,
    disko,
    sops-nix,
    # , nix-ld
    # , nixos-generators
    ...
  }: let
    inherit (users) masterUser;
    inherit (users) karolayne;
    users = import ./users.nix;
    system = "x86_64-linux";
    # zen-browser = inputs.zen-browser.packages."${system}".specific;
    # system-aarch64 = "aarch64-linux";

    unstable = import nixpkgs-unstable {
      inherit system;
      config.allowUnfree = true;
    };
    #pkgs-aarch64 = import nixpkgs-unstable {
    #  system = system-aarch64;
    #  config.allowUnfree = true;
    #};
    inherit (nixpkgs) lib;
    overlays = [rust-overlay.overlays.default];
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };
    mkSystem = name: cfg: let
      masterUsername = masterUser.name;
      additionalUserExists =
        (cfg.additionalUser or null)
        != null; # Variable must be boolean
      additionalUsername = cfg.additionalUser.name;
    in
      with lib;
        nixosSystem
        {
          inherit system;
          specialArgs =
            {
              inherit inputs unstable masterUser nix-direnv ;
            }
            // attrsets.optionalAttrs additionalUserExists {inherit (cfg) additionalUser;};
          modules =
            (
              if (builtins.hasAttr "isVPS" cfg && cfg.isVPS)
              then [
                # VPS only configuration
                ./hosts/vps-server
              ]
              else [
                ./modules
                ./hosts/configuration.nix
                ./hosts/${name}
                masterUser.user
                sops-nix.nixosModules.sops
                home-manager.nixosModules.home-manager
                # nix-ld.nixosModules.nix-ld
                {
                  nixpkgs.overlays = overlays;
                }
                nixos-cosmic.nixosModules.default
                {
                  home-manager = {
                    useGlobalPkgs = true;
                    useUserPackages = true;
                    extraSpecialArgs = {inherit pkgs unstable masterUser nix-direnv inputs;};
                    users =
                      {
                        # Load HM configuration for main user
                        "${masterUsername}".imports = [./home/${masterUsername}.nix];
                      }
                      // attrsets.optionalAttrs additionalUserExists {
                        # Load HM configuration for additional user
                        "${additionalUsername}".imports = [./home/${additionalUsername}.nix];
                      };
                  };
                }
              ]
            )
            # In case additional modules was passed
            ++ (cfg.modules or [])
            # Details from additional user
            ++ (
              if additionalUserExists
              then [cfg.additionalUser.user]
              else []
            );
        };
    # All hosts
    hosts = {
      n100 = {
        modules = [];
      };
      b450 = {
        modules = [];
      };
      gl62m = {
        # TODO: Maybe convert to a List
        additionalUser = karolayne;
      };
      thinkpad = {};
      vps-server = {
        modules = [disko.nixosModules.disko];
        isVPS = true;
      };
    };
  in
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux"];
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
          godot_rust = {
            path = ./templates/godot_rust;
            description = "nix flake new -t github:lluz55/nixos-config#godot_rust <directory>";
          };
        };
        #packages."x86_64-linux" = {
        #  aarch64-linux-iso = nixos-generators.nixosGenerate {
        #    system = "x86_64-linux";
        #    format = "iso";
        #    modules = [ ./modules/aarch64-linux-base.nix ];
        #  };
        #};
        #packages.${system}.neovim = neovim-flake.packages.${system}.maximal;
        nixosConfigurations = lib.mapAttrs mkSystem hosts;
      };
    };
}
