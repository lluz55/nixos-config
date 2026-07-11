# Bevy Template

Create a project from the main flake:

```sh
nix flake new -t github:lluz55/nixos-config#bevy my-bevy-game
```

Create a project from this standalone template flake:

```sh
nix flake new -t github:lluz55/nixos-config?dir=templates/bevy my-bevy-game
```

First time in the generated directory:

```sh
direnv allow
```

After that, just `cd` into the working directory.

## Compile-time notes

The Nix shell includes `clang`, `mold`, and `sccache`. Cargo is configured to link
with `mold`, and the shell enables `sccache` for local rebuilds. This template
pins a Rust version compatible with its Bevy 0.5 code, lockfile, and the current
Nix cargo build hook. Bevy dynamic
linking is enabled for faster development builds; disable it before shipping a
standalone release binary.
