---
title: "Recipe: Create a Mermaid Diagram from Natural Language"
description: "Generate, validate, and preview a Mermaid diagram without hand-writing syntax"
category: "cookbook"
level: "beginner"
time_estimate: "3 minutes"
related:
  - ../../commands.md
  - ../../generate.md
---

# Recipe: Create a Mermaid Diagram from Natural Language

**Time:** 3 minutes
**Level:** Beginner
**Prerequisites:** None (works from a plain-English description)

## Problem

I want an architecture/workflow/sequence diagram in my docs but don't want to hand-write Mermaid
syntax or debug why it doesn't render.

## Solution

1. **Describe it in natural language**

   ```
   /folio:docs:mermaid "user submits a form, API validates it, writes to the database, returns a confirmation"
   ```

   Why: the `input` argument accepts either a template type (`dependency`, `workflow`,
   `architecture`, `comparison`, `sequence`, `state`, `all`) or a natural-language description in
   quotes — no need to know Mermaid syntax up front.

2. **Or start from a template** if you know the diagram shape you want:

   ```
   /folio:docs:mermaid architecture
   ```

3. **Validate it renders correctly**

   ```
   /folio:docs:mermaid "..." --validate
   ```

   Why: `--validate` runs the diagram through MCP-powered validation after generation, catching
   syntax errors before you commit a diagram that fails to render on GitHub/mkdocs.

4. **Visually inspect before publishing**

   ```
   /folio:docs:mermaid "..." --validate --preview
   ```

   Why: `--preview` renders to SVG and opens it in a browser — the fastest way to catch a
   diagram that's syntactically valid but visually wrong (crossed lines, wrong direction).

5. **Save to a file** instead of stdout:

   ```
   /folio:docs:mermaid "..." --output docs/architecture.md
   ```

## Explanation

`docs:mermaid` is backed by the `mermaid-expert` agent and the `mermaid-linter` skill — the
command handles generation (from template or NL) and the linter skill handles ongoing syntax
health checks once the diagram is committed (also reachable via `/folio:docs:check`, which
includes mermaid health in its full sweep).

## Related recipes

- [Write a Tutorial for a New Feature](write-a-tutorial.md) — tutorials auto-generate learning-path
  diagrams via this same agent
- [Check Documentation Health Before a PR](check-docs-health-before-a-pr.md) — ongoing mermaid
  syntax validation after the diagram is committed

## What's Next

- [Commands Reference](../../commands.md)
- [Skills & Agents](../../skills-agents.md) — see `mermaid-expert`, `mermaid-linter`
