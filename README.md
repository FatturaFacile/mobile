# FatturaFacile Mobile

[![CI](https://github.com/FatturaFacile/mobile/actions/workflows/build.yml/badge.svg)](https://github.com/FatturaFacile/mobile/actions/workflows/build.yml)
[![Flutter](https://img.shields.io/badge/Flutter-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE)

Flutter client for the [FatturaFacile](https://github.com/FatturaFacile/FatturaFacile) ERP. It talks to the [`web-api`](https://github.com/FatturaFacile/web-api) REST API and works offline first: the UI reads from a local SQLite database and a sync engine exchanges changes with the server.

> **Status: early stage.** The app foundation (authentication, local database, sync, permissions, translations) and many feature modules are in the codebase, but the app has not been released. Expect incomplete screens.

## Overview

- **Targets:** Android, iOS, web, Windows, macOS and Linux (one codebase).
- **Offline first:** local SQLite (Drift), writes go to an outbox queue and are sent with idempotency keys, delta pull from the server, server wins by default, fiscal documents go to a conflict log for manual review.
- **Authentication:** OAuth2 authorization code with PKCE against the API, Sanctum bearer token, tokens in secure storage, optional biometrics.
- **Multi-tenancy and roles:** every request carries the tenant (`X-Tenant-Id`); permissions are checked on the client with `PermissionService`.
- **Languages:** `it`, `en`, `de`, `fr` (static ARB files plus translations fetched from the API).
- **Feature modules** under `lib/features/`, for example `auth`, `entities`, `field_service`, `inventory_count`, `wms`, `purchase_orders`, `general_ledger`, `italian_vat`, `swiss_vat`, `project_billing`, `shop_floor`, `shift_planning`. Their maturity varies.
- The API contract the app relies on is summarized in [docs/MAPPING.md](docs/MAPPING.md).

Main packages: `flutter_riverpod`, `drift`, `dio`, `fpdart`, `flutter_secure_storage`, `connectivity_plus`, `local_auth`, `intl`.

## Requirements

- Flutter stable with Dart `^3.13.5` (see `pubspec.yaml`)
- Android Studio (Android), Xcode and CocoaPods (iOS and macOS), Chrome (web), Visual Studio with the C++ workload (Windows) or Clang and CMake (Linux)
- A running `web-api` for anything beyond the login screen

## Getting started

Run the commands from the repository root.

```bash
git clone https://github.com/FatturaFacile/mobile.git
cd mobile
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # Drift code
flutter gen-l10n                                           # localization classes
flutter run                                                # default device
flutter run -d chrome
```

## Configuration

The API address is set at build time with `--dart-define`:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000   # Android emulator to a local API
```

Variable: `API_BASE_URL` (defaults to the production API). There is no `.env` file. Android signing and Firebase files (`key.properties`, `google-services.json`, `GoogleService-Info.plist`) are local only and ignored by git.

## Testing and linting

```bash
dart format --output=none --set-exit-if-changed .   # formatting
flutter analyze                                     # static analysis (flutter_lints)
flutter test                                        # unit and widget tests
flutter test --coverage                             # as in CI
```

Pre-push gate: format, analyze and test must all pass with no warnings.

## CI/CD and branching

- `dev` is the default branch. Open pull requests against `dev`. `main` is the release line.
- `Build & Test` (`build.yml`) runs `flutter analyze`, `flutter test --coverage` and a SonarQube scan on pushes and pull requests to `main`. It is not triggered by pull requests to `dev`, so run the gate above locally before pushing.
- There is no store release or deployment workflow yet.

## Project structure

```text
lib/
├── main.dart
├── app/        # app widget, providers, routing, session controller
├── core/       # config, database (Drift), error, localization, network (Dio), security, sync
├── design/     # design tokens generated from web-frontend (do not edit by hand)
├── features/   # one folder per module: domain/, data/, presentation/
└── l10n/       # ARB files and generated localization classes
test/           # mirrors lib/ (app, core, features)
docs/MAPPING.md # API contract used by the app
android/ ios/ linux/ macos/ web/ windows/   # platform hosts
```

## Related repositories

| Repository | Relation |
| :--- | :--- |
| [`web-api`](https://github.com/FatturaFacile/web-api) | Backend API (`/api/v1`, mobile endpoints under `/mobile`) |
| [`web-frontend`](https://github.com/FatturaFacile/web-frontend) | Web client; the design tokens come from it |
| [`database`](https://github.com/FatturaFacile/database) | Reference relational schema |
| [`FatturaFacile`](https://github.com/FatturaFacile/FatturaFacile) | Organization overview and repository map |

## Documentation

- [docs/MAPPING.md](docs/MAPPING.md): mobile, API and web client mapping
- Project wiki: [FatturaFacile/FatturaFacile wiki](https://github.com/FatturaFacile/FatturaFacile/wiki)

## License

[MIT](LICENSE)
