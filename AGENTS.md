# AGENTS.md

## Project & Stack Overview
- **Project**: Fattura Facile Mobile (`fattura_facile`)
- **Type**: Flutter / Dart cross-platform mobile client application (WMS scanner, transfer receipt & dispatch flows)
- **Dart SDK**: `^3.13.5` (running on Dart 3.14+)
- **Flutter**: 3.50.0+ (stable channel)
- **Architecture**:
  - Feature-driven modular layout (`lib/features/<feature>/`)
  - Layered separation: Data (`data/`), Domain Models (`models/`), State Management (`state/`), UI & Widgets (`ui/`)
  - Design Tokens: Central design system token definitions in `lib/design/ff_tokens.dart`
  - Localization: `lib/l10n/` (`ff_strings.dart`) with multi-language support (de, en, it, etc.)
  - Platform targets: Android, iOS, macOS, Linux, Windows, Web

## Directory Layout
- `lib/` - Application source code:
  - `lib/design/` - Design tokens and typography/color systems
  - `lib/features/wms/` - WMS module:
    - `data/` - API client and repository implementations (HTTP client)
    - `models/` - Immutable data transfer models, status enums, JSON mappings
    - `state/` - State management classes (e.g. `ChangeNotifier` state containers)
    - `ui/` - Screens, subviews, and reusable input/scan widgets
  - `lib/l10n/` - Localization strings and translation keys
  - `lib/main.dart` - Entrypoint configuring environment flags (`API_BASE_URL`, `API_TOKEN`, `TENANT_ID`)
- `test/` - Unit, state, and widget tests mirroring `lib/features/`
- `analysis_options.yaml` - Static analysis and lint configurations based on `package:flutter_lints`

## Coding & Quality Standards
- **Zero-Warning Tolerance**: Code must pass `flutter analyze` cleanly without warnings or errors.
- **Strict Typing**: Specify explicit types for public APIs, function signatures, and collection literals where appropriate.
- **Const Constructors**: Use `const` constructors wherever possible (`prefer_const_constructors`, `prefer_const_literals_to_create_immutables`).
- **Encapsulation**: Prefer private fields with getters/setters (`prefer_final_fields`).
- **Logging**: Do NOT use `print()` or `debugPrint()` in production code (`avoid_print` rule enabled).
- **Design Tokens**: Always use `FfTokens` and design tokens rather than hardcoded colors, spacing, or radius constants.
- **Localization**: Localize all user-facing strings through `FfStrings` / localized string providers; do not hardcode English/Italian text in widgets.

## Exact Verification & Quality Gate Commands
Run these commands locally before completing any task or committing changes:

- **Install Dependencies**:
  ```bash
  flutter pub get
  ```

- **Static Analysis & Linting**:
  ```bash
  flutter analyze
  ```

- **Unit & Widget Tests**:
  ```bash
  flutter test
  ```

- **Tests with Coverage (CI parity)**:
  ```bash
  flutter test --coverage
  ```

- **Format Code**:
  ```bash
  dart format lib test
  ```
