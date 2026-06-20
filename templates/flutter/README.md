# Flutter Template

Create a project from the main flake:

```sh
nix flake new -t github:lluz55/nixos-config#flutter my-flutter-app
```

Create a project from this standalone template flake:

```sh
nix flake new -t github:lluz55/nixos-config?dir=templates/flutter my-flutter-app
```

First time in the generated directory:

```sh
direnv allow
```

After that, just `cd` into the working directory.
