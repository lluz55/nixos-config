{
  description = "Pers system flake";
  nixConfig = {
    accept-flake-config = true;
    extra-substituters = [
      "https://nix-community.cachix.org"
      "https://cosmic.cachix.org"
    ];
    extra-trusted-substituters = [
      "https://nix-community.cachix.org"
      "https://cosmic.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "cosmic.cachix.org-1:Dya9IyXD4xdBehWjrkPv6rtxpmMdRel02smYzA85dPE="
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
    llm-agents.url = "github:numtide/llm-agents.nix";
    battery_up = {
      url = "github:lluz55/battery_up";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
    , llm-agents
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
      openai-codex = pkgs.callPackage ./pkgs/openai-codex/package.nix { inherit (pkgs) nodejs; };
      waydroidsu = pkgs.callPackage ./pkgs/waydroidsu/package.nix { };

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
            extraSpecialArgs = { inherit pkgs unstable masterUser nix-direnv inputs llm-agents openai-codex waydroidsu; };
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
                inherit inputs unstable masterUser nix-direnv llm-agents openai-codex waydroidsu;
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
			  s14 = {
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
      perSystem = { pkgs, ... }: {
        packages.waydroidsu = pkgs.callPackage ./pkgs/waydroidsu/package.nix { };
        packages.default = pkgs.callPackage ./pkgs/waydroidsu/package.nix { };
      };
    };
}
