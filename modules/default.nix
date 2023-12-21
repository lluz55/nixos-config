{ ... }:
{
  imports = [
    ../modules/options.nix
    ./configuration.nix
    ./desktops
    ./shell
    ./homeassistant
    ./frigate
  ];
}
