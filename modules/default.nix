{ ... }:
{
  imports = [
    ./options.nix
    ./configuration.nix
    ./hardware/nvidia.nix
    ./desktops
  ];
}
