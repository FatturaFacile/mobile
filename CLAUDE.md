@AGENTS.md

## Claude Code Execution Instructions
- **Quality gates**: run `flutter analyze` and `flutter test` before reporting work done. Zero warnings, zero failures.
- **Token efficiency**: `.claudeignore` hides generated code (`*.g.dart`, `*.freezed.dart`) and build dirs. Read `docs/MAPPING.md` for the API contract instead of re-reading `web-api`.
- **Worktrees**: significant edits go in a dedicated worktree/branch.
- Do not invent dependencies or endpoints; the contract lives in `docs/MAPPING.md`.

## Architecture map (progressive disclosure)
```
lib/core/            config · network (Dio) · database (Drift) · sync (outbox) · localization · theme · security
lib/features/<mod>/  domain/ (entities, repo interfaces, use cases) · data/ (remote, local, mappers, repo impl) · presentation/
lib/design/          ff_tokens.dart — GENERATED from web-frontend, never hand-edit
```
Existing `lib/features/wms` predates this layout; migrate it incrementally, do not break it.

## Offline-first rules
- UI reads only from SQLite, scoped `WHERE tenant_id = ?`. Writes update SQLite first (optimistic), then enqueue a `sync_queue` row.
- Outbox: FIFO per dependency; row UUID is sent as `Idempotency-Key`; client IDs are UUID v7 mapped to server IDs after sync.
- `sync_status`: `synced | pending_create | pending_update | pending_delete | conflict`. Server wins by default; fiscal documents go to the conflict log for manual review.
- Delta pull: `GET /mobile/sync/{entity}?updated_since&cursor`, store `server_time` per tenant+entity.
- Switching tenant: change query scope + `X-Tenant-Id`, drop in-memory providers, start a delta sync.

## i18n
No hardcoded UI strings. Locales `it, en, de, fr` loaded from `GET /translations/{locale}`, cached in SQLite, last-known copy used offline. A missing key renders an empty/neutral label, never the raw key.

## Headers
`Authorization: Bearer`, `X-Tenant-Id`, `X-Language-Code`, `Accept-Language`, `Idempotency-Key` (writes).

## Theme
Use `FfTokens`/`FfColors` (ThemeExtension in `lib/design/ff_tokens.dart`). No literal colors, radii or spacing.

## Verification
`flutter pub get` · `dart run build_runner build --delete-conflicting-outputs` · `flutter analyze` · `flutter test`
