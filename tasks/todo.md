# Tasks: folio#24

Branch for all work: a `feature/*` worktree off `dev` in folio (not created). Gates for every task: `python3 -m pytest tests/`, `./scripts/validate-counts.sh`, `mkdocs build --strict`.

## Phase 1: Foundation

- [ ] **T1 (S) Resolver test with allowlist.** Files: `tests/test_references.py`, `tests/data/craft_commands.txt`.
  - Acceptance: fails today listing exactly the 76 dead occurrences in 21 files; passes when a path-scoped allowlist covers them; a planted `/craft:site:nothing` and `/folio:docs:nothing` each make it fail.
  - Verify: run it before and after planting; the count printed equals 76.
  - Depends on: none.
- [ ] **T2 (XS) Decide the mapping.** Read `commands/docs/site.md`, `website.md`, `lint.md`; write the old-to-new table in `tasks/plan.md`. Open questions 1 and 2 are decided in `tasks/plan.md`.
  - Acceptance: every one of the 30 distinct dead commands has a target (folio command, or "remove").
  - Depends on: T1.

### Checkpoint: Foundation
- [ ] Gates pass with allowlist; the mapping table is approved by the author.

## Phase 2: Rewrite (one slice per family; each shrinks the allowlist)

- [ ] **T3 (M) `skills/docs/site-management/` (SKILL.md + 7 references, about 22 refs).** Acceptance: no dead refs; the skill still has its frontmatter; `validate-counts.sh` still sees 6 skills.
  - Depends on: T2.
- [ ] **T4 (S) Navigation, doc-classifier, mermaid-linter skills + `nav-update.md` (about 11 refs).** Acceptance: no dead refs. Depends on: T2.
- [ ] **T5 (M) `commands/docs/demo.md`, `workflow.md`, `prompt.md`, `site.md` (about 17 refs).** Acceptance: no dead refs; `/folio:docs:site` flags documented in the file still exist. Depends on: T2.
- [ ] **T6 (XS) `commands/docs/help.md` (4 dead refs: `git:worktree` example, Related line `docs:sync`, `docs:guide`, `docs:check`).** Acceptance: no dead refs; examples naming existing craft commands stay (decision 2). Depends on: T2.
- [ ] **T7 (S) One-offs:** `api`, `lint`, `check`, `guide`, `mermaid`, `website`, `generate`, `tutorial`, `quickstart`, plus `sync.md` pointers to `/folio:docs:update`, `analyze` and `done` (keep only where the text says "retired"). Acceptance: no dead refs outside the allowlist, and the allowlist is now only retired-command notes. Depends on: T2.

### Checkpoint: Rewrite
- [ ] Allowlist contains only retired-command notes; all three gates pass; author reviews the diff.

## Phase 3: Close-out

- [ ] **T8 (XS) `CLAUDE.md` count and changelog.** Fix "about 15 commands" (17), add a CHANGELOG entry via the project's release flow, no hand-edited counts. Acceptance: `validate-counts.sh` passes. Depends on: T3-T7.

### Checkpoint: Complete
- [ ] Issue #24 acceptance met; PR opened only when the author asks; no merge without asking.
