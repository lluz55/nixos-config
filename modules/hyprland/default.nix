{ ... }:
{
  imports = [ (import ./hyprland.nix) ]
    ++ [ (import ./variables.nix) ];
}
