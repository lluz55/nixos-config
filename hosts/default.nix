{ inputs, secrets, home-manager, nixpkgs, nixpkgs-unstable, sops-nix, master-user, karolayne, ... }:
let
  system = "x86_64-linux";

  unstable = import nixpkgs-unstable {
    inherit system;
    config.allowUnfree = true;
  };
  lib = nixpkgs.lib;
  pkgs = import nixpkgs {
    inherit system;
    config.allowUnfree = true;
  };
in
with lib;
{
  imports = [ ../users.nix ];
  n100 = nixosSystem
    {
      inherit system;
      specialArgs = {
        inherit inputs unstable master-user secrets;
      };
      modules = [
        ./n100
        ../modules/commom.nix
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

  b450 = nixosSystem {
    inherit system;
    specialArgs = {
      inherit inputs unstable master-user;
    };
    modules = [
      ./b450
      ../modules/commom.nix
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
      ../modules/commom.nix
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
