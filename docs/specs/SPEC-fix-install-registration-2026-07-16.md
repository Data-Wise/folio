# SPEC: Fix folio-install Silent Registration Failure (#18)

**Date:** 2026-07-16 · **Status:** Fix implemented — [Data-Wise/homebrew-tap#143](https://github.com/Data-Wise/homebrew-tap/pull/143) open, CI green, awaiting merge review
**Issue:** [Data-Wise/folio#18](https://github.com/Data-Wise/folio/issues/18)
**Repo:** **`homebrew-tap`** — the actual bug and fix live there, not in `folio`. This SPEC is
filed in `folio`'s `docs/specs/` because the issue is filed against folio and this is where a
folio-repo reader would look for it; the "How to drive this" section below points at the
homebrew-tap worktree where the code change actually happens.

## Problem

`brew install data-wise/tap/folio` copies plugin files successfully but never registers folio
with Claude Code — `claude plugin list` shows nothing, while the installer still prints
`✅ Folio plugin installed successfully!`. Root cause confirmed by diffing the generated
`Formula/folio.rb` against the working `Formula/craft.rb` in `~/projects/dev-tools/homebrew-tap`:

`generator/manifest.json`'s `folio` entry has **no `"features"` key** (`null`), while `craft`'s
entry sets `{"schema_cleanup": true, "branch_guard": true, "marketplace": true,
"claude_detection": true}`. `generator/generate.py`'s `generate_install_script()` (lines
108–123) only emits two blocks when their matching feature flag is true:

1. **`marketplace.sh`** (gated on `features.marketplace`) — mirrors the plugin into
   `~/.claude/local-marketplace/<name>/` and adds the `{"name", "source", "description"}` entry
   to `marketplace.json` via `jq`. Folio's formula has neither — so `folio` is never listed in
   the local marketplace, and `claude plugin install folio@local-plugins` (the next step) has
   nothing to install.
2. **`claude-detection.sh`** (gated on `features.claude_detection`) — sets `CLAUDE_RUNNING=false`
   (or `true` if `pgrep -x claude` finds a running process). Folio's formula lacks this block too,
   so `$CLAUDE_RUNNING` is **unset** in the generated script. The existing registration guard in
   `success.sh` — `if [ "$CLAUDE_RUNNING" = false ] && command -v claude &>/dev/null; then` —
   compares an empty string against the literal `false` and is always false. **Even if bug #1 were
   fixed alone, the registration call would still never execute.**

Both bugs must be fixed together; fixing only the marketplace block leaves the registration call
dead code.

## Scope

### In scope

- Add `"features": {"marketplace": true, "claude_detection": true}` to the `folio` entry in
  `homebrew-tap/generator/manifest.json`.
- Regenerate `Formula/folio.rb` via the existing generator (`generator/generate.py`) — do not
  hand-edit the `.rb` file, per the repo's own "never hand-edit counts/generated formulas"
  convention.
- Diff the regenerated `folio.rb` against the current one to confirm exactly the two blocks
  (`marketplace.sh`, `claude-detection.sh`) are newly inserted, with no unrelated drift (e.g. from
  a stale `command_count` or `sha256` in the manifest at generation time).
- A test or generator-level assertion that prevents a new `claude-plugin`-type formula from being
  added to the manifest without `marketplace` + `claude_detection` features (this is what let #18
  happen silently in the first place — folio was a first-time addition and nothing caught the
  missing flags).

### Explicitly out of scope

- Auto-creating the local marketplace manifest file itself if it's entirely missing (rare —
  `marketplace.sh` already no-ops safely via `[ -f "$MANIFEST_FILE" ]`); that's separate, existing
  behavior this SPEC doesn't touch.
- Any change to folio's own repo content (commands/skills/agents) — folio has no bug here.
- Retrofitting every other formula's manifest entry for the missing-features class of bug beyond
  confirming the generator-level guard (above) catches it going forward. Don't audit all 10+
  existing formulas as part of this fix — that's a separate, broader task if wanted later.

## Acceptance Criteria

- [ ] `homebrew-tap/generator/manifest.json`'s `folio` entry has
      `"features": {"marketplace": true, "claude_detection": true}`.
- [ ] `Formula/folio.rb` is regenerated (not hand-edited) and contains both the
      marketplace-manifest-mirroring block and the `CLAUDE_RUNNING` detection block, matching the
      shape already present in `Formula/craft.rb`.
- [ ] A fresh `brew install`/`brew reinstall` of the folio formula (or a direct run of the
      generated `bin/folio-install` script) results in `folio` appearing in
      `~/.claude/local-marketplace/.claude-plugin/marketplace.json`'s `.plugins[]` array, and
      `claude plugin list` shows `folio@local-plugins` afterward — proven with an actual
      before/after transcript, not just "should work now."
- [ ] A generator-level or test-level guard exists (e.g. in `homebrew-tap/tests/`) that fails CI
      if a `"type": "claude-plugin"` manifest entry is added/kept without
      `features.marketplace` and `features.claude_detection` both `true` — this is the structural
      fix that prevents recurrence for the next new plugin, not just this one instance.
- [ ] Existing `homebrew-tap` test suite (`tests/`) still passes after the manifest + formula
      change — no regression to other formulas' generated output (spot-check `craft.rb`,
      `rforge.rb` are byte-identical pre/post this change, since they already had both flags).

## Review Checklist

- [ ] Confirm no other `claude-plugin`-type formula in `manifest.json` is *also* missing these two
      flags (a quick grep/jq check across all entries) — if one is found, note it but do not fix
      it as part of this PR (see Explicitly out of scope); file a follow-up issue instead.
- [ ] The regenerated `folio.rb`'s `sha256`/`version` fields are untouched by this change (this
      fix only adds install-script blocks, it must not bump/re-point the release artifact).
- [ ] PR description explicitly notes this is a `homebrew-tap`-repo fix responding to a
      `folio`-repo issue, with a cross-link both ways (issue comment + PR body), so neither repo's
      history reads as orphaned.

## Key Files

- `homebrew-tap/generator/manifest.json` — `folio` entry (add `features`)
- `homebrew-tap/Formula/folio.rb` — regenerated output (do not hand-edit)
- `homebrew-tap/generator/generate.py` — `generate_install_script()` (read-only reference; no
  change expected unless the guard needs new logic here)
- `homebrew-tap/generator/blocks/marketplace.sh`, `claude-detection.sh` — the two blocks being
  newly included (read-only reference)
- `homebrew-tap/tests/` — add the manifest-guard test here (exact file TBD by whoever drives this;
  follow existing test naming, e.g. `test_marketplace_sync_resilience.sh`'s sibling pattern)

## Test Plan

| Tier | What |
|---|---|
| `unit`/`generator` | Regenerate all formulas from `manifest.json`, assert `folio.rb` diff is exactly the two new blocks, all other formulas byte-identical. |
| `e2e`/`dogfood` | Run the regenerated `bin/folio-install` (or a full `brew reinstall`) in a scratch `HOME`/`.claude` sandbox; grep the resulting `marketplace.json` for a `folio` entry; run `claude plugin list` and grep for `folio@local-plugins`. This is the test that can actually FAIL and is the one to quote in the PR body per this session's `e2e-before-pr` rule. |
| `count-cascade` | N/A — no command/skill/agent counts change; this is install-script plumbing only. |
| `dependency` | N/A — no new external dependency; `jq` is already a declared formula dependency. |

Stub the `e2e` test first (red), confirm it fails against the *current* `folio.rb` (proving it
would have caught #18), then make it pass against the regenerated one.

## Documentation

Per the doc-impact-rubric threshold (≥3): this is an internal generator/manifest fix with no
user-facing command, skill, or agent surface change — score is below threshold for
guide/refcard/demo/mermaid docs. The one doc update needed is a `homebrew-tap/CHANGELOG.md`
`[Unreleased]` entry noting the folio registration fix, and a comment on
[folio#18](https://github.com/Data-Wise/folio/issues/18) linking the fixing PR once merged.

- [ ] Guide — N/A, score <3
- [ ] Refcard — N/A, score <3
- [ ] Demo — N/A, score <3
- [ ] Mermaid — N/A, score <3
- [x] CHANGELOG `[Unreleased]` entry in `homebrew-tap`

## How to drive this

```bash
# homebrew-tap repo — this is where the actual fix lands, NOT folio
cd ~/projects/dev-tools/homebrew-tap
git worktree add ~/.git-worktrees/homebrew-tap/feature-fix-folio-install \
  -b feature/fix-folio-install-registration dev
cd ~/.git-worktrees/homebrew-tap/feature-fix-folio-install
# then implement per Acceptance Criteria above, or hand this SPEC to /craft:orch:drive
# in that worktree if homebrew-tap has the drive skill available.
```

Cross-link when opening the PR: reference `Data-Wise/folio#18` in the PR body, and comment back
on the issue with the PR link once merged.
