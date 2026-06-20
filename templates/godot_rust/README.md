# Godot Rust Template

Create a project from the main flake:

```sh
nix flake new -t github:lluz55/nixos-config#godot_rust my-godot-rust-game
```

Create a project from this standalone template flake:

```sh
nix flake new -t github:lluz55/nixos-config?dir=templates/godot_rust my-godot-rust-game
```

First time in the generated directory:

```sh
direnv allow
```

After that, just `cd` into the working directory.
