{
  description = "Personal NixOs system flake";
  # nixConfig = {
  #   extra-substituters = [
  #     "https://nix-community.cachix.org"
  #   ];
  #   extra-trusted-public-keys = [
  #     "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
  #   ];
  # };
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixvim = {
      url = "github:nix-community/nixvim/nixos-23.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
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
  };

  outputs = inputs @ { self, nixpkgs, nixpkgs-unstable, home-manager, sops-nix, flake-parts, ... }:
    let
      users = import ./users.nix;
      master-user = users.master-user;
      karolayne = users.karolayne;
    in

    flake-parts.lib.mkFlake { inherit inputs; }
      {
        systems = [ "x86_64-linux" ];
        flake = {
          templates.flutter = {
            path = ./templates/flutter;
            description = "nix flake new -t github:lluz55/nixos-config#flake .";
          };
          nixosConfigurations = (
            import ./hosts {
              inherit (nixpkgs) lib;
              inherit sops-nix;
              inherit inputs nixpkgs nixpkgs-unstable;
              inherit home-manager karolayne master-user;
            }
          );
        };
      };
}
