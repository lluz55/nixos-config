# Tauri + Dioxus Template Instructions

This template provides a Nix development shell for Rust desktop apps using Tauri and Dioxus-oriented tooling.

## Tooling

- Run project commands through `nix develop -c`, for example `nix develop -c cargo fmt`, `nix develop -c cargo clippy`, `nix develop -c cargo test`, and `nix develop -c cargo tauri dev`.
- Keep Rust, Node, pnpm, Tauri, WebKitGTK, GTK, and OpenSSL dependencies in `flake.nix`.
- Use the stable Rust toolchain defined in the flake; do not add rustup or system package manager setup steps.

## Project Conventions

- Keep frontend package-manager files and Rust lockfiles in sync when adding dependencies.
- Use `pnpm` for JavaScript dependencies because it is provided by the shell.
- Run formatting and tests from the Nix shell before finalizing changes.
- Keep generated build artifacts such as `target/`, `dist/`, and Tauri bundles out of the template.

## Refresh Guidance

- Check current Tauri 2 docs and docs.rs before generating commands, plugin setup, permissions, capabilities, or configuration keys.
- Keep Tauri permissions and capabilities least-privilege. Add filesystem, shell, updater, or system APIs only when the starter app actually uses them.
- Keep frontend and backend boundaries explicit: use Tauri commands for trusted Rust-side work and keep browser-facing data serialized through typed payloads.
- For Dioxus-oriented projects, verify the selected Dioxus version and CLI expectations before generating frontend code or dev commands.
