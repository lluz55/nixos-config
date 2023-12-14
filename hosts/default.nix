{ inputs, home-manager, nixpkgs, nixpkgs-unstable, sops-nix, master-user, karolayne, ... }:
let
  system = "x86_64-linux";

  pkgs = import nixpkgs {
    inherit system;
    config.allowUnfree = true;
  };
  unstable = import nixpkgs-unstable {
    inherit system;
    config.allowUnfree = true;
  };
  lib = nixpkgs.lib;
in
with lib;
{
  imports = [ ../users.nix ];
  n100 = nixosSystem {
    inherit system;
    specialArgs = {
      inherit inputs unstable master-user;
    };
    modules = [
      ./n100
      master-user.user
      home-manager.nixosModules.home-manager
      {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          extraSpecialArgs = { inherit pkgs unstable master-user; };
          users = {
            lluz.imports = [ ../home/lluz.nix ];
          };
        };
      }
    ];
  };
  gl62m = nixosSystem {
    inherit system;
    specialArgs = {
      inherit inputs unstable karolayne master-user;
    };

    modules = [
      ./gl62m
      karolayne.user
      master-user.user
      home-manager.nixosModules.home-manager
      {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          extraSpecialArgs = { inherit pkgs unstable; };
          users = {
            lluz.imports = [ ../home/lluz.nix ];
            karolayne.imports = [ ../home/karolayne.nix ];
          };
        };
      }
    ];
  };
}
