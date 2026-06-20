# NixOS system configuration Flake

## Modules
- [Cloudflared Connectors (Multi-Tunnel)](./modules/servers/README-cloudflared-connectors.md)

## Templates

Templates can be used from the main flake:

```shell
nix flake new -t github:lluz55/nixos-config#flutter my-flutter-app
nix flake new -t github:lluz55/nixos-config#zig my-zig-app
nix flake new -t github:lluz55/nixos-config#bevy my-bevy-game
nix flake new -t github:lluz55/nixos-config#godot_rust my-godot-rust-game
nix flake new -t github:lluz55/nixos-config#odin my-odin-app
nix flake new -t github:lluz55/nixos-config#tauri my-tauri-app
```

Each template is also a standalone flake template and has its own README:

- [Flutter](./templates/flutter/README.md)
- [Zig](./templates/zig/README.md)
- [Bevy](./templates/bevy/README.md)
- [Godot Rust](./templates/godot_rust/README.md)
- [Odin](./templates/odin/README.md)
- [Tauri + Dioxus](./templates/tauri/README.md)

## What to do
- Download and install [NixOS](https://nixos.org/download)
- Place private key in `/root/.ssh`
 
```shell
git clone git@github:lluz55/nixos-config.git ~/.nixos-config
cd ~/.nixos-config
sudo cp /etc/nixos/hardware-configuration.nix .
sudo nixos-rebuild switch --impure --flake .#<host>
```

### How to generate keys to use with SOPS-NIX
```
mkdir -p ~/.config/sops/age
nix-shell -p ssh-to-age --run "ssh-to-age -private-key -i ~/.ssh/id_ed25519 > ~/.config/sops/age/keys.txt"
```

## Install NixOS on any VPS

1. Generate ssh key
```bash
  ssh-keygen -t ed25519 -C "vps-key"
```
2. Copy public key and paste it in `users.users.root.openssh.authorizedKeys.keys` located in
```bash
  $EDITOR ./host/vps-server/default.nix
```
3. Installation
```bash
  nix run github:nix-community/nixos-anywhere -- --flake .#vps-server 
```
4. Log into vps server
```bash
  ssh -i path_to_server_private_key lluz@192.168.0.199
```
5. After config update
```bash
  nixos-rebuild switch --flake .#vps-server --target-host lluz@192.168.0.199
```

# References
- [ghostbuster91's config](https://github.com/ghostbuster91/nixos-router)
- [nixhero video about NixOS on VPS](https://www.youtube.com/watch?v=26jqQoS6SdQ)
