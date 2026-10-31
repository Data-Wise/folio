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
