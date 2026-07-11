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

## Flutter Best Practices

- Follow Effective Dart and the `flutter_lints` defaults. Keep identifiers, file names, imports, and formatting idiomatic instead of adding local style rules.
- Prefer small, focused widgets over large `build` methods. Extract reusable UI into `StatelessWidget` or `StatefulWidget` classes rather than helper methods when that gives stable identity, clearer rebuild boundaries, or testable UI.
- Use `const` constructors wherever possible, especially for static widget subtrees. Do not override widget `operator ==` for performance shortcuts.
- Keep expensive work out of `build`. Precompute data in state, view models, repositories, or async workflows, and use `StringBuffer` for repeated string assembly in loops.
- Avoid unnecessary `Opacity`, clipping, intrinsic layout passes, and visual effects that trigger `saveLayer()` in frequently rebuilt or scrolling UI. Confirm the visual tradeoff before adding them.
- Use lazy builders for long or unbounded lists and grids, such as `ListView.builder`, `GridView.builder`, and slivers. Avoid constructing entire scrollable collections eagerly.
- Separate UI, UI state, and data access. For non-trivial apps, prefer a clear UI layer plus data layer with views, view models, repositories, and services; add a domain/use-case layer only when it removes real complexity.
- Keep state ownership narrow. Use local widget state for ephemeral UI state, and lift state into view models or app-level state only when multiple widgets or routes need it.
- Profile performance on a real device in profile mode before optimizing. Debug mode and emulators can misrepresent frame timing, startup cost, and jank.
- Use DevTools, the performance overlay, and targeted benchmark or integration tests when performance is a requirement. Treat unexplained dropped frames as a bug to measure, not guess at.
- Monitor release size when adding assets, fonts, plugins, deferred components, or platform features. Prefer compressed, resolution-appropriate assets and remove unused resources.
- Add tests at the lowest useful level: unit tests for pure Dart and view-model logic, widget tests for UI behavior, and integration tests for platform/device flows or performance-sensitive journeys.

## Refresh Guidance

- Check the official Flutter SDK archive or release index before changing pinned Flutter versions, Dart constraints, Gradle versions, or Android SDK expectations.
- Prefer `flutter create` conventions unless the template has an explicit reason to be smaller than a generated app.
- Add tests at the right level: unit tests for pure Dart logic, widget tests for UI behavior, and integration tests only when platform/device behavior is part of the template.
- Keep analyzer settings explicit and conservative. Do not silence lints globally unless the template documents why the rule is unsuitable.
