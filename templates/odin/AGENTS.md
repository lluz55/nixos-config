# Odin Template Instructions

This template provides an Odin development shell with graphics and language-server dependencies through Nix flakes.

## Tooling

- Run project commands through `nix develop -c`, for example `nix develop -c odin version`, `nix develop -c odin build .`, and `nix develop -c odin test .`.
- Keep Odin, OLS, SDL, OpenGL, Vulkan, and Raylib-related dependencies in `flake.nix`.
- Do not install editor language-server binaries outside the Nix shell as part of template setup.

## Project Conventions

- Prefer explicit package layout and simple Odin modules.
- Keep generated binaries, cache directories, and editor artifacts out of the template.
- If changing the pinned Odin or OLS source revisions, update the corresponding Nix hashes in the same change.
- Verify build-sensitive edits with `nix develop -c odin build .` when an Odin source tree exists.

