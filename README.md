# NixOs system configuration Flake

## Building
```shell
```bash
git clone git@github:lluz55/nixos-config.git ~/.nixos-config
cd ~/.nixos-config
sudo cp /etc/nixos/hardware-configuration.nix .
sudo nixos-rebuild switch --flake .#<host>
```

## Inspiration
* [LLuz' NixOs System Configuration Flake](https://github.com/lluz55/nixos-config)

