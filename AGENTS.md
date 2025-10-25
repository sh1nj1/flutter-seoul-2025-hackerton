# Repository Guidelines

## Project Structure & Module Organization
The Flutter application code lives in `lib/`, with `main.dart` bootstrapping the widget tree. Platform shells stay under `android/`, `ios/`, `web/`, `linux/`, `macos/`, and `windows/`; edit these only when platform-specific wiring is required. Place tests in `test/` and mirror the library structure using `*_test.dart` files. Add shared assets or fonts under `assets/` and register them in `pubspec.yaml` so they ship with the build.

## Build, Test, and Development Commands
Run `flutter pub get` after adding dependencies to refresh generated lockfiles. Use `flutter analyze` to surface lint and type issues before committing. Execute `flutter test` for unit and widget suites; add `--coverage` when you need a report in `coverage/lcov.info`. Launch a local debugger with `flutter run -d macos` (or another device id). Produce release artifacts with `flutter build apk --release` or the platform-appropriate build command.

## Coding Style & Naming Conventions
The project extends `package:flutter_lints`, so honor those rules and keep changes to `analysis_options.yaml` minimal. Format Dart files with `dart format .` (2-space indent) prior to review. Use PascalCase for widgets and classes, camelCase for methods and variables, SCREAMING_SNAKE_CASE for compile-time consts, and prefix private members with `_`. Prefer descriptive widget file names such as `timer_panel.dart` to match the primary class.

## Commit & Pull Request Guidelines
Existing history uses concise imperative summaries (for example, `init - flutter create clamndown`). Follow that structure: a short directive headline (<60 chars), optional context after a hyphen, and details in the body. Reference issue numbers in the body when relevant. Pull requests should include a problem statement, solution notes, testing evidence (command output or screenshots for UI changes), and highlight follow-up items so reviewers can plan next steps.
