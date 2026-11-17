# GitHub Copilot Instructions

See [AGENTS.md](../AGENTS.md) for full project architecture and conventions.

## Core Directives & Quality Gates
- **Framework**: Flutter (Dart SDK `^3.13.5`)
- **Architecture**: Modular feature-first under `lib/features/<feature>/` (data, models, state, ui).
- **Standards**: Zero-warning tolerance on `flutter analyze`, use `const` widgets, use tokens from `lib/design/ff_tokens.dart`, localize strings via `lib/l10n/ff_strings.dart`.
- **Essential Commands**:
  - Analyze: `flutter analyze`
  - Test: `flutter test`
  - Format: `dart format lib test`
