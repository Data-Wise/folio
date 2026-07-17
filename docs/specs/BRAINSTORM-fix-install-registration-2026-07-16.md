# BRAINSTORM: folio-install Silent Registration Failure (#18)

**Date:** 2026-07-16 · **Depth:** quick · **Focus:** ops
**Issue:** [Data-Wise/folio#18](https://github.com/Data-Wise/folio/issues/18)

## Context Scan

- No prior SPEC/BRAINSTORM existed for this topic in `folio/docs/specs/` (directory didn't exist
  until this session).
- Issue #18 already contains a detailed root-cause hypothesis and a suggested fix — used as the
  starting point, then verified directly against the generator source rather than taken on faith.
- Verified against `~/projects/dev-tools/homebrew-tap`:
  - `generator/generate.py` (`generate_install_script`, lines 84–149) gates two install-script
    blocks behind `features.marketplace` and `features.claude_detection`.
  - `generator/manifest.json`'s `folio` entry has no `"features"` key at all; `craft`'s entry has
    both flags `true`.
  - The generated `Formula/folio.rb` confirms the theory exactly: no marketplace-mirroring block,
    and the `success.sh` block's `$CLAUDE_RUNNING` guard references a variable that's never set
    (since `claude-detection.sh` was never included).
- Related prior work in the same repo: PR #134 ("retry marketplace sync, degrade to advisory")
  addressed a *different* failure mode (marketplace sync flakiness for formulas that already have
  the feature flags) — it does not touch or fix this issue, since folio never had the flags to
  begin with.

## Finding

Two bugs, same manifest entry, must be fixed together:

1. Missing `features.marketplace` → no marketplace.json entry ever added.
2. Missing `features.claude_detection` → `$CLAUDE_RUNNING` never set → the *existing* "register
   plugin" call in `success.sh` is unreachable dead code even after fixing bug 1 alone.

## Options Considered

| Option | Verdict |
|---|---|
| Hand-patch `Formula/folio.rb` directly | Rejected — violates the repo's own "generated files are regenerated, not hand-edited" convention (same class of rule as `bump-version.sh` for counts); would silently drift from the next generator run. |
| Fix manifest + regenerate (chosen) | Correct fix, matches existing pattern for every other working formula. |
| Add a runtime fallback in `bin/folio-install` that checks for/creates the marketplace entry itself | Rejected — duplicates logic the generator already has correctly for every other plugin; the bug is a *configuration* gap (missing flags), not a *logic* gap. Fixing config is smaller and keeps one source of truth. |
| Broader audit: check all other formulas for the same missing-flags gap | Deferred — out of scope for this SPEC (see Explicitly out of scope); a generator-level guard test (in the SPEC's Acceptance Criteria) protects against *future* recurrence, which covers the important case without scope creep now. |

## Recommendation

Fix at the config layer (`manifest.json`), regenerate, add a structural test so a future new
plugin can't ship the same way. Captured as
[`SPEC-fix-install-registration-2026-07-16.md`](SPEC-fix-install-registration-2026-07-16.md).

## Test-Plan Scaffolding

See the SPEC's Test Plan section — `e2e`/`dogfood` tier is the one that can actually fail and
should be quoted in the eventual PR body; `unit`/`generator` tier catches unrelated formula drift.

## Documentation Scaffolding

Doc-impact score is below threshold (internal generator fix, no user-facing surface). Only a
`homebrew-tap/CHANGELOG.md` `[Unreleased]` line is warranted — see SPEC Documentation section.

## Next Command

The fix itself lives in `homebrew-tap`, not `folio` — see the SPEC's "How to drive this" for the
worktree command. No `--orch` handoff is offered here: this is a single, well-scoped two-line
config fix plus one generator-guard test, not a multi-agent implementation problem.
