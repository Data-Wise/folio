# Changelog

All notable changes to the folio plugin will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-07-16

First stable release. folio was extracted from craft's docs-authoring surface via
history-preserving `git filter-repo` (v4.0.0 train, `Data-Wise/craft`'s
`ORCHESTRATE-folio-split.md`).

### Added

- 17 commands: `/folio:hub`, `/folio:do`, and 15 `/folio:docs:*` commands, plus 6 skills and 6
  agents, carried over from craft with full git history preserved (#1, #5).
- `/folio:do` — thin keyword-table dispatcher over folio's own commands, no craft-scale
  complexity scoring or orchestration (#2).
- Behavioral test coverage: routing-trace tests for `/folio:do` and generic behavioral checks
  (substantive body, referenced arguments, resolvable file references) across all 16 other
  commands — 112 tests total, up from structural-only coverage (#6).
- Per-family documentation (Discovery / Generate / Validate) covering when to reach for which
  command, plus the non-obvious distinctions within each family (#7).

### Fixed

- Removed a leftover cross-plugin dispatch: `docs:sync`'s `--orch` flag called into
  `/craft:orch` directly, against folio's own no-cross-plugin-dispatch design (#4).
- `plugin.json`'s `agents` field had an invalid shape (`"./agents"` as a bare string); corrected
  to an explicit array of agent file paths. `agents/docs/demo-engineer.md` was missing its YAML
  frontmatter entirely (#8).

## [0.1.0] - 2026-07-10

Initial extraction scaffold (`T1.3`-`T2.8`): repo skeleton, tooling adaptation, CI, docs site.
