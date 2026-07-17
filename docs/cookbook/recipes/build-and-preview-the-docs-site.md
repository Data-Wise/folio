---
title: "Recipe: Build and Preview the Docs Site"
description: "Local mkdocs build and hot-reload preview before publishing"
category: "cookbook"
level: "beginner"
time_estimate: "2 minutes"
related:
  - ../../commands.md
---

# Recipe: Build and Preview the Docs Site

**Time:** 2 minutes
**Level:** Beginner
**Prerequisites:** `mkdocs.yml` present in the repo (folio's own site, or a project folio is
documenting)

## Problem

I edited docs content and want to see the rendered site locally before pushing — and I want the
build to actually fail on broken links/nav instead of silently succeeding.

## Solution

1. **Strict build (fails on warnings)**

   ```bash
   mkdocs build --strict
   ```

   Why: plain `mkdocs build` treats broken links and orphaned nav pages as warnings only —
   `--strict` turns them into build failures, which is what you want before a PR.

2. **Local hot-reload preview**

   ```bash
   mkdocs serve
   ```

   Opens `http://127.0.0.1:8000` with hot-reload — edit a page, see it update without
   re-running the command.

3. **If it's not an mkdocs project**, the equivalent commands are:

   | Site type | Build | Preview |
   |---|---|---|
   | Quarto (`_quarto.yml`) | `quarto render` | `quarto preview` |
   | pkgdown (R, `_pkgdown.yml`) | `Rscript -e 'pkgdown::build_site()'` | `pkgdown::preview_site()` |

## Explanation

This is the `site-management` skill's `build`/`preview` operations, invoked directly rather than
through a `/folio:docs:*` command — site lifecycle (init/build/preview/deploy/publish/status)
moved to that skill during the folio split rather than staying as standalone commands. The skill
auto-detects which of mkdocs/Quarto/pkgdown a project uses before picking the command.

## Related recipes

- [Check Documentation Health Before a PR](check-docs-health-before-a-pr.md) — content-level
  checks (staleness, mermaid) that a build alone won't catch

## What's Next

- [Commands Reference](../../commands.md)
- `skills/docs/site-management/SKILL.md` — full site lifecycle reference
