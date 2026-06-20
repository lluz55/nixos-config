# Zig Template Instructions

This template provides a Zig development shell using `zig-overlay` and ZLS through Nix flakes.

## Tooling

- Run project commands through `nix develop -c`, for example `nix develop -c zig version`, `nix develop -c zig build`, and `nix develop -c zig test src/main.zig`.
- Use the Zig compiler and ZLS versions provided by `flake.nix`; do not add system package manager setup steps.
- Keep shell compatibility changes in the flake rather than introducing separate environment scripts.

## Project Conventions

- Prefer standard Zig layout when adding source files: `build.zig`, `src/`, and tests colocated with the code they exercise.
- Run `nix develop -c zig fmt .` before finalizing Zig source changes.
- Avoid committing generated `zig-cache`, `.zig-cache`, or `zig-out` directories.
- Keep the template minimal; add libraries only when they are required by the generated starter project.

