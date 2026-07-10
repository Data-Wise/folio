# Session Plan: Finish T2.4 → CP-2 (folio Phase 2)

> Scope of THIS session. Master plan of record: craft worktree `tasks/todo.md` +
> `docs/plans/ORCHESTRATE-folio-split.md`. Repo: `~/projects/dev-tools/folio` on
> `feature/extraction`. **Constraint: sequential/inline execution — NO agent fan-out for
> mechanical salvage (locked course-correction 2026-07-09).** Salvage SOURCE bodies live in
> craft `commands/site/*.md` + `commands/docs/nav-update.md` (still present until Phase 3).

## State at session start

- Phase 1 + CP-1: ✅ done. T2.1/T2.2/T2.3: ✅ done.
- **T2.4 partial** (`fd33bc3`): salvaged `site:build`→`site-management/references/build.md`,
  `site:check`→`.../check.md`, demoted `frameworks.md`. deploy/progress = no unique logic (no ref).
- Pending: publish · status · update · nav-update salvage · check-links→docs:check merge ·
  line-conservation audit · then T2.5–T2.8 + CP-2.

## Architecture decisions (locked — do not relitigate)

- ADR-002 salvage-then-delete: extract ONLY unique logic not already in the skill body →
  `references/<sub>.md`. If the skill fully covers it, NO reference (that's why deploy/progress
  produced none).
- Reference file pattern = the existing `build.md`/`check.md` frontmatter + "additional detail"
  framing. Match it exactly.
- Counts via `bump-version.sh`/`validate-counts.sh` only. folio floors: 15 cmds / 6 agents / 6 skills.

## Task list (vertical slices — one command's full salvage per task)

### Phase 2 completion

- [ ] **T2.4a** Salvage `site:publish` (364L) → `site-management/references/publish.md`
  - Acceptance: unique-logic-only diff vs skill body; frontmatter matches build.md pattern
  - Verify: `diff`-audit note (source lines → kept vs covered); file renders
  - Files: `skills/docs/site-management/references/publish.md` · Size: **S**
- [ ] **T2.4b** Salvage `site:status` (266L) → `site-management/references/status.md`
  - Acceptance/Verify: same as T2.4a · Size: **S**
- [ ] **T2.4c** Salvage `site:update` (352L) → `site-management/references/update.md`
  - Acceptance/Verify: same as T2.4a · Size: **S**
- [ ] **T2.4d** Salvage `docs:nav-update` → `skills/docs/navigation/references/nav-update.md`
  - Acceptance: unique logic in the `navigation` skill's references (NOT site-management)
  - Verify: diff-audit note · Size: **S**
- [ ] **T2.4e** Merge `check-links` → `docs:check`: fold link-checking into folio's
  `commands/docs/check.md` (a links section/flag); handle the now-redundant `check-links.md`
  - Acceptance: `docs:check` has a links section or `--links` flag; no orphaned dispatch
  - Verify: grep `docs:check` body for links coverage; routing trace · Size: **S**
- [ ] **T2.4f** Line-conservation audit (ADR-002 R2): Σ salvaged-ref lines + skill-covered lines
  ≈ Σ source lines for all 7 killed site cmds + nav-update; record ledger note
  - Acceptance: no unique logic dropped; ledger note committed · Size: **XS**

### Checkpoint CP-2a (T2.4 complete) — ASK before proceeding to T2.5

- [ ] All salvage refs present + line-conservation ledger clean
- [ ] `git status` clean, changes committed on `feature/extraction`
- [ ] **Human review before T2.5** (folio CI wiring is a new sub-scope)

### Phase 2 remainder (only after CP-2a approval)

- [ ] **T2.5** folio `ci.yml` (pytest + structure + counts, floors ~15/6/6); actionlint clean · **S**
- [ ] **T2.6** folio `homebrew-release.yml` + `aggregator-sync.yml` (parameterized mirrors) · **M**
- [ ] **T2.7** `/folio:hub` index + minimal `mkdocs build --strict`-clean docs site · **M**
- [ ] **T2.8** verify: counts + structure + spot-E2E (docs:tutorial equivalence) · **S**

### Checkpoint CP-2 — ASK

- [ ] folio suites green · history proof (`git log --follow` ×3) · hub present → record outcome

## Risks

| Risk | Impact | Mitigation |
|---|---|---|
| Salvage drops unique logic | High | Per-task diff vs skill body; T2.4f conservation audit |
| Salvage from craft, not folio-grafted source | Med | Source = craft `commands/site/*.md` (confirmed present); read there |
| check-links merge leaves orphan dispatch | Med | T2.4e routing trace |
| dev moves under branch | Low | folio `feature/extraction` is isolated; rebase-check at CP-2 |

## Build order

T2.4a → T2.4b → T2.4c → T2.4d → T2.4e → T2.4f → **CP-2a (ASK)** → T2.5…T2.8 → CP-2.
One commit per task (or per 2-3 salvages), leak-scan before any push.
