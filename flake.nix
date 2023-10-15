{
  description = "Personal NixOs system flake";

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
  };

  outputs = inputs @ { self, nixpkgs, nixpkgs-unstable, home-manager, ... }:
    let
      var = {
        user = "lluz";
        terminal = "kitty";
        editor = "nvim";
        wallpaper = "./wallpapers/landscape.png";
      };
    in
    {
      nixosConfigurations = (
        import ./hosts {
          inherit (nixpkgs) lib;
          inherit inputs nixpkgs nixpkgs-unstable home-manager var;
        }
      );
    };
}
