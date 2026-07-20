# CLAUDE.md — folio

Docs-authoring toolkit plugin for Claude Code. Extracted from craft in the v4.0.0 split
(plan of record: craft's `ORCHESTRATE-folio-split.md`).

## Surface (target at v1.0.0)

**≈15 commands · 6 agents · 6 skills.** Commands under `/folio:docs:*`; discovery via
`/folio:hub`. folio owns docs AUTHORING; craft keeps release-plumbing docs
(`/craft:docs:update`, `/craft:docs:changelog`) — the caller-based cut. No cross-plugin
dispatch in either direction.

## docs-standards contract

folio's tools consume the shared standards library at `~/projects/dev-tools/docs-standards`
(Quarto + MkDocs templates, style conventions) by **path convention**:

- Resolve `~/projects/dev-tools/docs-standards/` at runtime; if present, templates and style
  rules load from there.
- **Fallback (standards repo absent):** folio's bundled defaults under
  `skills/docs/*/references/` apply, and tools note the degradation explicitly — never fail
  hard on a missing standards checkout.
- No submodule, no version pin — the contract is the path + graceful fallback.

## Git Workflow

`main` (protected, PR-only) ← `dev` (integration) ← `feature/*` (worktrees). Never commit to
`main`; never write feature code on `dev`. Conventional commits. Same discipline as craft —
see the global `~/.claude/CLAUDE.md` for the full rules.

## Testing

| Tier | Command |
|---|---|
| Full suite | `python3 -m pytest tests/` |
| Counts | `./scripts/validate-counts.sh` (keys on SKILL.md only; floors 15/6/6) |
| Site | `mkdocs build --strict` (also enforced automatically by `ci.yml` on every PR, not just at release) |

Run all three in the tree a PR ships from, before opening it.

## Release

`dev → main` PR (merge-commit) → tag → GitHub release → homebrew-release.yml +
aggregator-sync.yml auto-propagate (tap formula + marketplace). Count/version cascade via
`./scripts/bump-version.sh` — never hand-edit counts. `homebrew-tap`'s `main` is branch-protected
(PR-only + required checks), so `homebrew-release.yml`'s tap-push step opens a `bot/folio-*`
branch + PR and enables GitHub native auto-merge rather than pushing directly.

## Provenance

Command/agent/skill files carry craft-era git history (`git log --follow` works across the
extraction boundary). MIGRATION map: craft's `MIGRATION-v4.md`.

## Known validator finding (recorded 2026-07-09)

`npx @anthropic-ai/claude-code plugin validate .` errors on root `CLAUDE.md` ("not loaded as
project context") for plugin-path validation. This file is REPO-DEV context (loaded when a
session works in this repo), not plugin-shipped context — same layout as craft/savant, which
pass only because their validator run takes the marketplace-manifest path. folio CI validates
structure via tests + this documented exception; plugin-shipped context lives in skills.
