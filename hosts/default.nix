{ inputs, home-manager, nixpkgs, nixpkgs-unstable, master_user, karolayne, ... }:
let
  system = "x86_64-linux";

  pkgs = import nixpkgs {
    inherit system;
    config.allowUnfree = true;
  };
  #
  unstable = import nixpkgs-unstable {
    inherit system;
    config.allowUnfree = true;
  };
  lib = nixpkgs.lib;

in
with lib;
{
  n100 = nixosSystem {
    inherit system;
    specialArgs = {
      inherit inputs unstable master_user;
    };
    modules = [
      ./n100
      master_user.user
      home-manager.nixosModules.home-manager
      {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          extraSpecialArgs = { inherit nixpkgs unstable master_user; };
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
      inherit inputs unstable master_user karolayne;
    };

    modules = [
      ./gl62m
      master_user.user
      karolayne.user
      home-manager.nixosModules.home-manager
      {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          extraSpecialArgs = { inherit nixpkgs unstable; };
          users = {
            lluz.imports = [ ../home/lluz.nix ];
            karolayne.imports = [ ../home/karolayne.nix ];
          };
        };
      }
    ];
  };
}
