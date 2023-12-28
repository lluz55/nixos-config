# NixOS system configuration Flake

## What to do
- Download and install [NixOS](https://nixos.org/download)
- Place private key in `/root/.ssh`
 
```shell
git clone git@github:lluz55/nixos-config.git ~/.nixos-config
cd ~/.nixos-config
sudo cp /etc/nixos/hardware-configuration.nix .
sudo nixos-rebuild switch --impure --flake .#<host>
```


