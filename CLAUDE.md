@AGENTS.md

- Follow [AGENTS.md](AGENTS.md) for all architecture, `it`/`de`/`fr`/`en` i18n, quality gates, and `dev`-only Git rules.
- Claude-only: `.claudeignore` hides generated (`*.g.dart`, `*.freezed.dart`) and build dirs; read [docs/MAPPING.md](docs/MAPPING.md) instead of `web-api`.
- Run significant edits in a dedicated worktree/branch, merge locally to `dev`, and clean up branches/worktrees afterward.
