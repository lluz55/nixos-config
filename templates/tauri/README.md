# Tauri + Dioxus Template

Create a project from the main flake:

```sh
nix flake new -t github:lluz55/nixos-config#tauri my-tauri-app
```

Create a project from this standalone template flake:

```sh
nix flake new -t github:lluz55/nixos-config?dir=templates/tauri my-tauri-app
```

First time in the generated directory:

```sh
direnv allow
```

After that, just `cd` into the working directory.
