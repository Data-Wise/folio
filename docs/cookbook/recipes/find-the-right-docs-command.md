---
title: "Recipe: Find the Right Docs Command"
description: "Use the Hub to discover the exact folio command for any documentation task"
category: "cookbook"
level: "beginner"
time_estimate: "2 minutes"
related:
  - ../../commands.md
  - ../../discovery.md
---

# Recipe: Find the Right Docs Command

**Time:** 2 minutes
**Level:** Beginner
**Prerequisites:** folio installed

## Problem

I want to find the right folio command for a documentation task without memorizing all 17
commands.

## Solution

1. **Open the Hub**

   ```
   /folio:hub
   ```

   Why: folio is small enough for a single-screen hub — no category drill-down needed. It
   shows every command grouped under START HERE / Generate / Validate.

2. **Not sure which generator you need?** Route through the generator dispatcher instead of
   picking one directly:

   ```
   /folio:docs:generate
   ```

   Why: `/folio:docs:generate` is the unified router across all 9 doc generators (api, guide,
   tutorial, quickstart, help, prompt, workflow, website, site) — it asks what you're
   documenting and picks the right one.

3. **Just want to know what's stale?** Skip discovery entirely:

   ```
   /folio:docs:sync
   ```

   Why: `docs:sync` detects code changes since the docs were last touched and classifies what
   documentation needs updating — the fastest path when you don't know if anything needs doing
   at all.

## Explanation

folio's 17 commands break into three groups: **Discovery** (`hub`, `do`, `docs:generate`,
`docs:sync`), **Generate** (the 9 content generators for a specific doc type), and **Validate**
(`docs:check`, `docs:lint`). The Hub is the entry point for "what exists"; `docs:generate` is the
entry point for "I know what I'm documenting, not which command makes it."

## What's Next

- [Commands Reference](../../commands.md) — all 17 commands listed by category
- [Generate an API Reference](generate-an-api-reference.md) — your first generator recipe
- [Check Documentation Health Before a PR](check-docs-health-before-a-pr.md)
