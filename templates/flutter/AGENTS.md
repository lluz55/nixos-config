# Flutter Template Instructions

This template is a Flutter application development shell backed by Nix flakes.

## Tooling

- Run project commands through `nix develop -c`, for example `nix develop -c flutter --version`, `nix develop -c flutter test`, and `nix develop -c flutter build apk`.
- When creating or refreshing a Flutter project, use the latest stable Flutter release from the official Flutter release index instead of hardcoding a version in this template.
- Keep Android SDK and JDK changes in `flake.nix`; do not install SDK components outside the Nix shell.

## Project Conventions

- Prefer idiomatic Flutter structure: `lib/` for app code, `test/` for widget/unit tests, and generated platform directories only when needed.
- Run `nix develop -c dart format .` before finalizing Dart changes.
- Use `nix develop -c flutter analyze` and `nix develop -c flutter test` for verification when the generated project contains Flutter sources.
- Keep secrets, signing keys, and local device configuration out of the template.
