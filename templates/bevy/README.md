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
