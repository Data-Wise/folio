---
title: "Recipe: Write a Tutorial for a New Feature"
description: "Generate a progressive, hands-on tutorial with GIF demos and mermaid diagrams"
category: "cookbook"
level: "intermediate"
time_estimate: "10 minutes"
related:
  - ../../commands.md
  - ../../generate.md
---

# Recipe: Write a Tutorial for a New Feature

**Time:** 10 minutes
**Level:** Intermediate
**Prerequisites:** A shipped feature you want to teach users to use

## Problem

I just shipped a feature and want a step-by-step tutorial for it — not just a reference page —
including a demo GIF and a learning-path diagram, without writing all of that by hand.

## Solution

1. **Run the tutorial generator**

   ```
   /folio:docs:tutorial
   ```

   Why: `docs:tutorial` orchestrates the full tutorial pipeline in one command instead of
   requiring you to separately record a demo, draw a diagram, and write the prose.

2. **Let it walk the pipeline:**
   - Analyzes the project/feature for tutorial-worthy content
   - Creates a step-by-step tutorial structure
   - Generates VHS tapes for the key demo steps
   - Adds mermaid diagrams for the learning path
   - Creates the tutorial page in the docs site
   - Updates site navigation to include it

3. **Review the generated GIF and diagram placement** — VHS tapes and mermaid diagrams are
   generated content; skim them before publishing.

## Explanation

`docs:tutorial` is backed by the `tutorial-engineer` agent (progressive, hands-on tutorial
structure) working alongside `demonstration-builder` (terminal GIF recording) and
`mermaid-expert` (diagram authoring). The command sequences all three so you get one finished,
navigable tutorial page rather than three disconnected artifacts you'd have to assemble
yourself.

## Related recipes

- [Create a Mermaid Diagram from Natural Language](create-a-mermaid-diagram.md) — if you want a
  diagram outside the tutorial pipeline
- [Build and Preview the Docs Site](build-and-preview-the-docs-site.md) — see the tutorial live
  before publishing

## What's Next

- [Commands Reference](../../commands.md)
- [Skills & Agents](../../skills-agents.md) — see `tutorial-engineer`, `demonstration-builder`,
  `mermaid-expert`
