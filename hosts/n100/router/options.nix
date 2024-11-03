{ config, secrets, lib, ... }:
let
  macs = {
    poco = builtins.readFile config.sops.secrets."macs/poco".path;
    gl62m = builtins.readFile config.sops.secrets."macs/gl62m".path;
    b450 = builtins.readFile config.sops.secrets."macs/b450".path;
    rn10c = builtins.readFile config.sops.secrets."macs/rn10c".path;
    honor = builtins.readFile config.sops.secrets."macs/honor".path;
    mibox2 = builtins.readFile config.sops.secrets."macs/mibox2".path;
    tabs5e = builtins.readFile config.sops.secrets."macs/tabs5e".path;
    a55 = builtins.readFile config.sops.secrets."macs/a55".path;
  };
in
with lib;{
  options = {
    # Interfaces
    WAN = mkOption {
      type = types.str;
      default = "enp1s0";
    };
    LAN0 = mkOption {
      type = types.str;
      default = "enp2s0";
    };
    LAN1 = mkOption {
      type = types.str;
      default = "enp3s0";
    };
    LAN2 = mkOption {
      type = types.str;
      default = "enp4s0";
    };

    # TODO: To use git ssh key authentication the private key must be in `/root/.ssh` 
    # when using `nix-rebuild switch...`
    # TODO: Use own module for this
    macs = mkOption {
      type = types.attrs;
      default = macs;
    };
  };
}
