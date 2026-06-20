# Bevy Template Instructions

This template is a Rust game project using Bevy and Nix flakes.

## Tooling

- Run project commands through `nix develop -c`, for example `nix develop -c cargo fmt`, `nix develop -c cargo test`, and `nix develop -c cargo run`.
- When creating or refreshing a Bevy project, check the current published Bevy crate version from an authoritative source such as crates.io or docs.rs instead of reusing a version from this template.
- Match Bevy code examples to the API of the Bevy version selected for the generated project.

## Project Conventions

- Keep gameplay code small and testable; prefer components, resources, events, and plugins over global state.
- Put reusable game logic behind plugins and keep `main` as a thin app composition layer.
- When changing dependencies, update `Cargo.lock` and verify with `nix develop -c cargo test`.
- Avoid broad feature additions to Bevy unless the template needs them. Prefer explicit features such as `wayland` over enabling unnecessary platform or asset support.
