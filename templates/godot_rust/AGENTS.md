# Godot Rust Template Instructions

This template is a Rust project shell for Godot-oriented development with Nix flakes.

## Tooling

- Run project commands through `nix develop -c`, for example `nix develop -c cargo fmt`, `nix develop -c cargo test`, and `nix develop -c cargo build`.
- Use the Rust toolchain provided by `flake.nix`; do not add ad hoc rustup instructions to this template.
- Keep runtime library path changes in the Nix shell so Godot, Vulkan, OpenGL, and X11 dependencies stay reproducible.

## Project Conventions

- Keep Rust code formatted with `nix develop -c cargo fmt`.
- Prefer small Rust modules with focused tests over large Godot integration blocks.
- When adding crates, update `Cargo.lock` and verify with `nix develop -c cargo test`.
- Keep `assets/` for project assets and avoid committing generated build outputs.

## Refresh Guidance

- Check the godot-rust book and current `godot` crate docs before generating GDExtension registration, class, signal, property, or lifecycle code.
- Use the public `godot` crate API rather than private generated modules or undocumented internals.
- Align Cargo features with the Godot editor/runtime version. Enable at most one `api-*` feature and avoid experimental features unless the generated project explicitly needs them.
- Keep pure Rust logic testable without launching the Godot editor; reserve editor/runtime checks for integration behavior that cannot be verified with `cargo test`.
