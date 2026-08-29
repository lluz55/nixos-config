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

### GitHub access token for private flake inputs

Some flake inputs (`dl-conn`, `dl-home-control`, `searxng-mpc`, `home-config`, …) live in
private `lluz55/*` repos. Fetching them requires a GitHub token with `repo` scope, which
is passed to Nix via the `access-tokens` setting.

The token is **not** stored in `flake.nix`'s `nixConfig` or in any plaintext file in this
repo — both approaches leak the secret (`nixConfig` is committed, plaintext files sit
readable on disk). Instead it lives encrypted in `secrets/secrets.yaml` under
`nix_tokens.github.com`, and `hosts/configuration.nix` renders it at activation time into
a runtime-only file that `/etc/nix/nix.conf` references via Nix's `!include` directive
(see `man nix.conf`; `!include <path>` is silently skipped if the path doesn't exist yet,
unlike the required `include <path>`):

```nix
sops.secrets."nix_tokens/github.com" = { };
sops.templates."nix-access-tokens.conf".content = ''
  access-tokens = github.com=${config.sops.placeholder."nix_tokens/github.com"}
'';
# in nix.extraOptions:
!include ${config.sops.templates."nix-access-tokens.conf".path}
```

This way the token only ever exists decrypted under `/run/secrets/`, never in the Nix
store or in git.

**Bootstrap problem:** on a machine's first-ever `nixos-rebuild switch`, the sops-rendered
file doesn't exist yet (it's only created *by* that same activation), so the build can't
fetch the private inputs to build itself. Break the cycle by passing a token in for that
one run only — it can come from an already-authenticated `gh` CLI session:

```shell
sudo nixos-rebuild switch --flake .#<host> --impure --option access-tokens "github.com=$(gh auth token)"
```

Using `$(gh auth token)` keeps the literal token out of shell history and terminal
scrollback. After this first activation succeeds, the sops-rendered file exists and every
later rebuild picks up the token automatically — no flag needed.

**Rotating the token:** edit the secret with `sops secrets/secrets.yaml` and update
`nix_tokens.github.com`, then rebuild.

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
