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

## Refresh Guidance

- Consult Bevy's official docs and docs.rs for the selected version before generating example systems, schedules, input handling, UI, or rendering code.
- Prefer narrow Bevy Cargo feature sets. Use `default-features = false` with profiles or explicit features only when the starter project benefits from the smaller compile surface.
- Keep development-only features such as hot reloading, diagnostics, or dynamic linking out of release defaults unless the generated project explicitly asks for them.
- For CI-friendly examples, include deterministic unit tests for pure gameplay logic and avoid requiring a GPU window for the default test path.

## Compile-Time Guidance

- Keep compile-speed tools in the Nix shell instead of system setup instructions. This template provides `clang`, `mold`, `sccache`, and the Rust toolchain through `flake.nix`.
- Because this starter currently uses Bevy 0.5 APIs and lockfile contents, keep Rust pinned to a compatible 1.60.x-era toolchain unless you also refresh Bevy, `Cargo.lock`, and the example code together.
- Use `mold` through `.cargo/config.toml` as `-fuse-ld=mold`, not through a hardcoded `/nix/store/...` path, so refreshed flakes keep working after garbage collection or package updates.
- Let the dev shell set `RUSTC_WRAPPER=sccache`; do not bake `sccache` into `.cargo/config.toml`, because Nix package builds should remain independent of a user-local compiler cache.
- Keep Bevy dynamic linking as a development optimization only. Before release packaging, remove the version-appropriate Bevy dynamic-linking feature, such as this template's `dynamic` feature, and verify the standalone build with `nix build`.
- Use the commented Cranelift config only after refreshing to a newer Bevy and nightly Rust. Keep dependencies on LLVM and switch back to LLVM for release, wasm, or unexplained runtime/codegen issues.
