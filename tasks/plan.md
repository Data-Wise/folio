# Implementation Plan: folio dead `/craft:*` references (folio#24)

Spec: https://github.com/Data-Wise/folio/issues/24. Drafted 2026-10-30 against folio `dev` 272fa3c and craft 5521e9cf3. Planning only: nothing has been written in folio.

## Overview

76 occurrences of `/craft:<cmd>` in 21 folio command and skill files name commands craft no longer ships (`site:*`, `docs:analyze`, `docs:validate`, `docs:feature`, `docs:nav-update`, `git:clean`, `git:worktree`, `git:status`; `docs:check`, `docs:guide` and `docs:sync` are folio's own commands under the wrong prefix). The work removes or retargets them and adds a test so the drift cannot return.

## Dependency graph

```
T1 resolver test + allowlist (red baseline: 76)
 ├─ T2 decision: what replaces the site:* family (docs:site / docs:website) ── open question 1
 │    ├─ T3 site-management skill + references (14 + 8 refs)
 │    ├─ T4 navigation, doc-classifier, mermaid-linter skills
 │    └─ T5 demo, workflow, prompt, site commands
 ├─ T6 help.md (open question 2: does docs:help document craft commands on purpose?)
 └─ T7 one-offs: api, lint, check, guide, mermaid, website, + sync.md retired pointers
T8 CLAUDE.md count, CHANGELOG, final gates (needs T3-T7)
```

## Architecture decisions

- Test first. T1 lands red (it lists all 76) with an allowlist for retired-command notes, so each later task turns a named subset green and the final state is provably complete. The test needs a planted-defect positive control so it can fail.
- Resolver scope: every `/craft:<name>` must match a command file or skill in craft's current tree; every `/folio:<name>` must match a folio file. craft is another repo, so the test reads a pinned list in `tests/data/craft_commands.txt` (refreshed by a documented command) rather than a path outside the repo.
- Vertical slices are per file family: each task changes its files, runs the resolver for those files, and leaves the suite green except for the not-yet-done families (the allowlist temporarily holds those paths and shrinks each task).
- Do not delete `skills/docs/site-management`: `scripts/validate-counts.sh` has a floor of 6 skills, and there are exactly 6. Rewrite it instead.
- No hand-edited counts; use `./scripts/bump-version.sh` for any count or version change.

## Task list

See `tasks/todo.md`. Phases: Foundation (T1-T2), Rewrite (T3-T7), Close-out (T8).

## Risks and mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| Replacements point at a folio command that does not do the job | Med | T2 decides the mapping from the command bodies (`docs:site`, `docs:website`, `docs:lint`) before any bulk edit |
| Bulk replace hits quoted history or fenced examples that describe craft on purpose | Med | Replace by file with a preview; never `replace_all` blindly; grep after |
| Resolver test is vacuous | High | Positive control: a planted `/craft:site:nothing` must fail it |
| Pinned craft list goes stale | Low | Test file names the refresh command and the craft commit it was taken from |
| `help.md` intentionally documents craft commands | Low | Open question 2, answered before T6 |

## Decisions (author approved the plan 2026-10-30; recommendations adopted)

1. **site-management:** rewrite it to describe folio's `docs:site` and `docs:website`; do not delete it (skill count floor 6). Reason: keeps the count and gives the `site` flags one documented home.
2. **`docs:help`:** it deliberately documents any command, including craft's (its Purpose says "one command to document any command"), so examples that name existing craft commands (`/craft:check`, `/craft:docs:update`) stay. Only the `git:worktree` example (command gone) and the Related line (`docs:sync`, `docs:guide`, `docs:check` are folio's own) change. T6 shrinks to those lines.
3. **Craft command list:** a pinned `tests/data/craft_commands.txt` recording the craft commit it came from and the one-line refresh command. Reason: folio's tests cannot read another repo's tree.
4. **Process:** worktree `~/.git-worktrees/folio/feature-craft-ref-cleanup`, branch `feature/craft-ref-cleanup` off `origin/dev`. No PR until the author asks; no merge without asking.

## T2: mapping of dead references (for author approval)

Measured by `python3 tests/test_references.py` at folio `dev` 272fa3c: 30 dead `/craft:` commands (76 occurrences) and 5 dead `/folio:` names (9 occurrences). Targets were chosen from the command bodies (`docs:site` has `--preview`, `--deploy`, `--validate`; `docs:check` reports links, staleness, navigation and a Mermaid health score; `docs:sync` states it replaced `analyze` and `done`; craft still owns `docs:update [feature]`, `docs:changelog` and `site:deploy`).

| Dead reference (occurrences) | Action | Target |
|---|---|---|
| `/craft:docs:check`, `docs:guide`, `docs:sync` (1 each, `help.md:208`) | prefix fix | `/folio:docs:check`, `/folio:docs:guide`, `/folio:docs:sync` |
| `/craft:docs:analyze` (6) | retarget | `/folio:docs:sync` (classification was merged into it) |
| `/craft:docs:validate` (2) | retarget | `/folio:docs:check` for `site.md:304`; `api.md:246` (validate the generated spec): drop the line unless T7 finds a folio check for OpenAPI |
| `/craft:docs:feature` (2) | retarget | `/craft:docs:update "<feature>"` (craft keeps `update [feature]`) |
| `/folio:docs:update` (5, `sync.md`) | retarget | `/craft:docs:update` (folio does not ship it) |
| `/craft:site:check` (6), `/craft:site:status` (8) | retarget | `/folio:docs:check` (links, navigation, Mermaid health score) |
| `/craft:site:preview` (3) | retarget | `/folio:docs:site --preview` |
| `/craft:site:update` (4) | retarget | `/folio:docs:site` |
| `/craft:site:publish` (6) | retarget | `/craft:site:deploy` (still in craft; `docs:site --deploy` calls it) |
| `/craft:site:build` (7) | replace | the plain command `mkdocs build --strict` |
| `/craft:git:worktree` (5), `git:clean` (3), `git:status` (1) | replace | the plain git commands (`git worktree add`, `git branch -d`, `git status`); drop table rows that only advertise them |
| `/craft:site:progress` (3) | remove | no equivalent in either plugin |
| `/craft:site:add`, `nav`, `audit`, `consolidate`, `create`, `init`, `theme` (2, 4, 3, 2, 1, 1, 1) | remove | no executor exists; in `prompt.md` the prompts are used manually |
| `/craft:docs:nav-update` (3) | reword as history | it appears as the title of a salvaged-detail note and the skill's mode list |
| `/folio:docs:check-links` (1), `/folio:docs:analyze` (1), `/folio:docs:done` (1) | keep as history | "retired" notes in `check.md:337` and `sync.md:439-440`; stay on the allowlist |
| `/folio:docs:validate` (1, `mermaid-linter/SKILL.md:384`) | retarget | `/folio:docs:check` |

Two lists in `skills/docs/site-management/` are history, not instructions: its "consolidates the following commands (removed in v3.0.0)" paragraph and `references/update.md` / `nav-update.md` titles. T3 and T4 reword them to plain text ("the retired craft site commands: init, create, ...") so the slash form no longer matches, instead of allowlisting them. That makes T3 smaller than planned.

Approval needed: this table (author), especially the `site:build` to plain `mkdocs build --strict` and the removals.
