# Copilot instructions

Project: Flutter / Dart.

Full cross-tool rules: `.ai/rules/project.md` (read it first).

## Essentials

- Write all code, comments, commit messages and documentation in English.
- Fix every error you meet, also outside the request.
- Never add dependencies or secrets; follow the sibling files of the area you change.
- Keep UI, state and data access in separate layers; widgets stay small.
- Follow `analysis_options.yaml`; `flutter analyze` must report no issue.
- Payloads match the web-api FormRequests exactly.

## Commands

- `flutter pub get`
- `flutter analyze` and `dart format .`
- `flutter test`
