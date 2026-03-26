{
  description = "Pers system flake";
  nixConfig = {
    accept-flake-config = true;
    extra-substituters = [
      "https://nix-community.cachix.org"
    ];
    extra-trusted-substituters = [
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
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
    rust-overlay.url = "github:oxalica/rust-overlay";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    vscode-server.url = "github:nix-community/nixos-vscode-server";
  };

  outputs =
    inputs @ { nixpkgs
    , nixpkgs-unstable
    , home-manager
    , flake-parts
    , nix-direnv
    , rust-overlay
    , disko
    , sops-nix
    , ...
    }:
    let
      inherit (users) masterUser;
      inherit (users) karolayne;
      users = import ./users.nix;
      system = "x86_64-linux";

      unstable = import nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      };
      inherit (nixpkgs) lib;
      overlays = [ rust-overlay.overlays.default ];
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

      desktopProfile = [
        ./modules
        ./hosts/configuration.nix
        masterUser.user
        sops-nix.nixosModules.sops
        home-manager.nixosModules.home-manager
        {
          nixpkgs.overlays = overlays;
        }
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            extraSpecialArgs = { inherit pkgs unstable masterUser nix-direnv inputs; };
            users = {
              "${masterUser.name}".imports = [ ./home/${masterUser.name}.nix ];
            };
          };
        }
      ];

      mkSystem = name: cfg:
        let
          additionalUserExists = (cfg.additionalUser or null) != null;
        in
        with lib;
        nixosSystem
          {
            inherit system;
            specialArgs =
              {
                inherit inputs unstable masterUser nix-direnv;
              }
              // attrsets.optionalAttrs additionalUserExists { inherit (cfg) additionalUser; };
            modules = [ ./modules/rtl88x2bu.nix ./hosts/${name} ]
              ++ (cfg.modules or [ ])
              ++ lib.optional additionalUserExists {
                   home-manager.users."${cfg.additionalUser.name}".imports = [ ./home/${cfg.additionalUser.name}.nix ];
                   imports = [ cfg.additionalUser.user ];
                 };
          };
      hosts = {
        n100 = {
          modules = desktopProfile;
        };
        b450 = {
          modules = desktopProfile;
        };
        gl62m = {
          modules = desktopProfile;
          additionalUser = karolayne;
        };
        thinkpad = {
          modules = desktopProfile;
        };
        vps-server = {
          modules = [ disko.nixosModules.disko ];
        };
      };
    in
    flake-parts.lib.mkFlake { inherit inputs; } {
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
          godot_rust = {
            path = ./templates/godot_rust;
            description = "nix flake new -t github:lluz55/nixos-config#godot_rust <directory>";
          };
        };
        nixosConfigurations = lib.mapAttrs mkSystem hosts;
      };
    };
}
