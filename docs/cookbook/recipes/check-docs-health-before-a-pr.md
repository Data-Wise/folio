---
title: "Recipe: Check Documentation Health Before a PR"
description: "Validate links, staleness, navigation, and mermaid health in one pass"
category: "cookbook"
level: "beginner"
time_estimate: "2 minutes"
related:
  - ../../commands.md
  - ../../validate.md
---

# Recipe: Check Documentation Health Before a PR

**Time:** 2 minutes
**Level:** Beginner
**Prerequisites:** A docs site (mkdocs.yml or equivalent) in the repo

## Problem

I'm about to open a PR that touched code and/or docs and want to catch broken links, stale
pages, and orphaned nav entries before a reviewer does.

## Solution

1. **Preview first, fix nothing yet**

   ```
   /folio:docs:check --dry-run
   ```

   Why: `--dry-run` (alias `-n`) previews every check without touching any files — safe to run
   on a dirty working tree.

2. **Run the full health check**

   ```
   /folio:docs:check
   ```

   This checks, by default: broken internal/external links, stale docs (pages not updated when
   the code they document changed), navigation health, and mermaid diagram syntax.

3. **Auto-fix what's safe to fix**

   ```
   /folio:docs:check --fix
   ```

   Why: `--fix` applies only the subset of findings that are mechanically safe to correct
   (e.g. a renamed file's internal links) — it does not rewrite prose or guess at content fixes.

4. **For quick markdown-only issues** (not links/staleness), use the lighter-weight linter
   instead:

   ```
   /folio:docs:lint
   ```

## Explanation

`docs:check` is the validation counterpart to the nine `docs:*` generators — it doesn't produce
new content, it audits what already exists. Running `--dry-run` before `--fix` lets you see the
blast radius of an auto-fix before committing to it, which matters most on a shared branch where
an unexpected mass-edit is disruptive.

## Related recipes

- [Build and Preview the Docs Site](build-and-preview-the-docs-site.md) — `mkdocs build --strict`
  catches a different class of issue (build-time nav/link errors) than `docs:check` does
  (content-time staleness/link health)

## What's Next

- [Commands Reference](../../commands.md)
- [Validate](../../validate.md) — full reference for `docs:check` and `docs:lint`
