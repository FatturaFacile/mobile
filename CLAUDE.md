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


## Git Workflow & Direct Merge Policy (STRICT)
- **Target Branch (`dev`):** Integrate all work directly into `dev` via local merge. **NEVER commit, merge, or push directly to `main`**, and **NEVER create Pull Requests (`gh pr create` / `gh pr`).**
- **Worktree Handling:** If running inside a linked git worktree, finish commits and tests on the feature branch, then run the merge on `dev` from the primary repository root (`git checkout dev && git pull --rebase origin dev && git merge --no-ff <branch>`).
- **Conflict Resolution:** Resolve any merge conflict markers autonomously, preserving Clean Architecture layers, Drift/SQLite migrations, and all 4 ARB localization files (`it`, `de`, `fr`, `en`).
- **Pre-Push Quality Gate:** Before `git push origin dev`, execute and ensure zero issues on:
  - `dart format --output=none --set-exit-if-changed .`
  - `flutter analyze`
  - `flutter test`
- **Cleanup:** Delete merged local/remote feature branches and remove temporary worktrees (`git worktree remove` + `git branch -D <branch>`).