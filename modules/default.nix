{ ... }:
{
  imports = [
    ../options.nix
    ./configuration.nix
    ./desktops
    ./shell
    ./homeassistant
    ./frigate
  ];
}
