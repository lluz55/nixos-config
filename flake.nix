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
  };

  outputs = inputs @ { self, nixpkgs, nixpkgs-unstable, home-manager, ... }:
    let
      master_user = {
        name = "lluz";
        terminal = "kitty";
        editor = "nvim";
        wallpaper = "./wallpapers/landscape.png";
        is_router = true;
        user = {
          users.users.lluz = {
            isNormalUser = true;
            hashedPassword = "$6$JogEHvo2duy/W0Wa$6cFqRMbSTcry5v8kkfsXna61/TsWH0F5q0HsbXP.tMZvfvXydQX8EanJdiIcMijuLhyqj5Deg8HL/cerMuEO7/";
            extraGroups = [ "audio" "camera" "networkmanager" "video" "wheel" "docker" ];
          };
        };
      };
      karolayne = {
        user = {
          users.users.karolayne = {
            isNormalUser = true;
            hashedPassword = "$6$/yQn3vgw4HMwHhrm$TPlUa7xHtN3c3dXOFL5kOk7jVugIYtr.DmoI7v7lFy9sQNkLOwmxf.ksfMm7nXmeJTGuqW58Qdi.NISbxbjlg1";
            extraGroups = [ "audio" "camera" "video" ];
          };
        };
      };
    in
    {
      nixosConfigurations = (
        import ./hosts {
          inherit (nixpkgs) lib;
          inherit inputs nixpkgs nixpkgs-unstable;
          inherit home-manager master_user karolayne;
        }
      );
    };
}
