{
  description = "Personal NixOs system flake";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
  };

  outputs = inputs @ { self, nixpkgs, nixpkgs-unstable, home-manager, sops-nix, flake-parts, ... }:
    flake-parts.lib.mkFlake
      { inherit inputs; }
      {
        systems = [ "x86_64-linux" ];
        perSystem = { pkgs, system, nixpkgs', ... }:
          {
            imports = [
              (import ./shells/flutter.nix {
                inherit system nixpkgs;
                inherit (nixpkgs) lib;
              })
            ];
          };
      };
}


