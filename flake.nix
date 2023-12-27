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
      url = "github:nix-community/home-manager/master";
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

  outputs = inputs @ { self, nixpkgs, nixpkgs-unstable, home-manager, flake-parts, ... }:
    let
      users = import ./users.nix;
      master-user = users.master-user;
      karolayne = users.karolayne;
      secrets = import (builtins.fetchGit {
        url = "git+ssh://git@github.com/lluz55/secrets.git";
        ref = "master";
      });
    in

    flake-parts.lib.mkFlake { inherit inputs; }
      {
        systems = [ "x86_64-linux" ];
        flake = {
          templates.flutter = {
            path = ./templates/flutter;
            description = "nix flake new -t github:lluz55/nixos-config#flutter <directory>";
          };
          nixosConfigurations = (
            import ./hosts {
              inherit (nixpkgs) lib;
              inherit secrets;
              inherit inputs nixpkgs nixpkgs-unstable;
              inherit home-manager karolayne master-user;
            }
          );
        };
      };
}
