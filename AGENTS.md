# AGENTS.md

## Stack & Targets
- **App**: Fattura Facile Mobile (`fattura_facile`) — Flutter `3.50+` (stable), Dart `^3.13.5` (3.14+), Android/iOS/Web/Windows/macOS/Linux.
- **Core packages**: `flutter_riverpod` (`^3.5.0`), `drift` + `sqlite3_flutter_libs`, `dio`, `fpdart`, `flutter_secure_storage`, `connectivity_plus`, `material_ui`, `cupertino_ui`, `intl`.
- **API contract**: Single reference is [docs/MAPPING.md](docs/MAPPING.md); never invent endpoints/dependencies or re-scan `web-api`.

## Architecture & Layout
- `lib/app/`: `FatturaFacileApp`, Riverpod providers, routing, session controller.
- `lib/core/`: `config` (`--dart-define=API_BASE_URL`), `database` (`AppDatabase`, Drift), `error` (`Failure`), `localization` (`TranslationService`), `network` (`Dio` + interceptors), `security` (PKCE S256, `TokenStore`, RBAC/ABAC `PermissionService`, `SnapshotCipher`), `sync` (`SyncEngine`, `SyncOrchestrator`).
- `lib/features/<mod>/`: Clean Architecture layers — `domain/` (entities, repo interfaces, use cases), `data/` (remote, local DAOs/tables, mappers, repo impl), `presentation/` (providers, screens, widgets).
- `lib/features/wms/`: legacy layout (`data/`, `models/`, `state/`, `ui/`); migrate incrementally, never break it.
- `lib/design/ff_tokens.dart`: GENERATED from `web-frontend` (`pnpm tokens:sync`); never hand-edit.
- `test/`: mirrors `lib/` (`app/`, `core/`, `features/`).

## Offline-First SQLite (Drift) & Sync
- UI reads only from local SQLite scoped `WHERE tenant_id = ?`; writes mutate SQLite first (optimistic), then enqueue `sync_queue`.
- Outbox (`sync_queue`): FIFO honoring `dependsOn`; queue row UUID sent as `Idempotency-Key`; client IDs are UUID v7 mapped to `serverId` post-sync.
- `SyncStatus`: `synced | pendingCreate | pendingUpdate | pendingDelete | conflict`; server wins by default, fiscal documents go to conflict log for manual review.
- Delta pull: `GET /mobile/sync/{entity}?updated_since&cursor`; persist `serverTime`/`cursor` per `(tenantId, entity)` in `sync_cursors`.
- Schema changes: bump `AppDatabase.schemaVersion`, add `onUpgrade` migration, preserve `PRAGMA foreign_keys = ON`, regenerate with `build_runner`.
- Tenant switch: update query scope + `X-Tenant-Id`, drop tenant-scoped in-memory providers, trigger delta sync.

## Network & Auth
- Headers (`ContextInterceptor`): `Authorization: Bearer`, `X-Tenant-Id`, `X-Language-Code`, `Accept-Language`, `Accept: application/json`, plus `Idempotency-Key` on writes.
- Auth: OAuth2 PKCE S256 (`POST /mobile/auth/pkce/authorize` -> `POST /mobile/auth/pkce/token`); map `DioException` via `mapDioError` to domain `Failure`.

## Localization (`it`, `de`, `fr`, `en`)
- Zero hardcoded user-facing strings in widgets or state.
- Static ARB ([l10n.yaml](l10n.yaml)): update all 4 files (`lib/l10n/app_it.arb`, `app_de.arb`, `app_fr.arb`, `app_en.arb`; template `app_en.arb`) and regenerate (`flutter gen-l10n`).
- Dynamic API dictionary: `TranslationService` (`GET /translations/{locale}`) cached in SQLite (`translations`) for offline use; missing keys return empty/neutral label, never raw key.
- Legacy WMS strings (`lib/l10n/ff_strings.dart`, `FfStrings` / `L`): maintain parity across `it`, `de`, `fr`, `en` (enforced by tests).

## Coding & UI Standards
- Zero-warning tolerance under [analysis_options.yaml](analysis_options.yaml) (`flutter_lints`).
- Strict explicit types on public APIs, function signatures, and collection literals.
- Enforce `const` constructors/literals (`prefer_const_constructors`, `prefer_const_literals_to_create_immutables`) and private `final` fields (`prefer_final_fields`).
- No `print()` or `debugPrint()` in production code (`avoid_print`).
- Theme: use `FfColors` (`ThemeExtension`) and `ffThemeData` from `lib/design/ff_tokens.dart`; no hardcoded colors, radii, or spacing.

## Quality Gates & Commands
- Setup & codegen: `flutter pub get` · `dart run build_runner build --delete-conflicting-outputs` · `flutter gen-l10n`
- Format code: `dart format .`
- Pre-push gate (ALL must pass with zero warnings/errors):
  `dart format --output=none --set-exit-if-changed . && flutter analyze && flutter test`
- Coverage (CI parity): `flutter test --coverage`

## Strict Git Workflow (`dev`-only, ZERO PRs, ZERO Leftovers)
- **Target branch**: integrate all work directly into `dev` via local merge from primary repo root:
  `git checkout dev && git pull --rebase origin dev && git merge --no-ff <branch>`
- **FORBIDDEN**: NEVER commit, merge, or push to `main`; NEVER create Pull Requests (`gh pr create` / `gh pr`).
- **Worktrees**: if working in a linked git worktree, finish commits/tests on the feature branch, then run the `dev` merge from the primary repo root.
- **Autonomous conflict resolution**: resolve all merge conflicts autonomously, preserving Clean Architecture, strict types, Drift/SQLite migrations, and all 4 locales (`it`, `de`, `fr`, `en`).
- **Push gate**: NEVER push to `origin dev` unless `dart format --output=none --set-exit-if-changed . && flutter analyze && flutter test` all pass with zero warnings/errors.
- **Mandatory cleanup**: after pushing `dev`, ALWAYS delete merged local/remote feature branches (`git branch -D <branch>`, `git push origin --delete <branch>`), remove linked worktrees (`git worktree remove --force <path> && git worktree prune`), and delete session temp/debug files so `git status` is clean.
