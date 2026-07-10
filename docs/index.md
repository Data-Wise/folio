# folio

Docs-authoring toolkit for Claude Code: tutorials, guides, API docs, mermaid diagrams, doc
health checks, and site management.

Extracted from [craft](https://github.com/Data-Wise/craft) as part of its v4.0.0 split — craft
retains its dev-ops surface (code/test/ci/git/release/orchestrate); folio owns documentation
authoring, health checks, and site lifecycle. Full commit history preserved via `git filter-repo`.

## Quick start

```bash
claude plugin marketplace add data-wise/tap
claude plugin install folio@data-wise
```

```bash
/folio:hub              # command discovery hub
/folio:docs:check        # full documentation health check
/folio:docs:sync         # detect code changes, classify doc needs
```

## What's included

- **16 commands** — generation (api, guide, tutorial, quickstart, help, prompt, workflow,
  website, site, demo, mermaid), validation (check, lint), and discovery (hub, generate, sync)
- **6 skills** — auto-activate from conversation context (site lifecycle, nav sync, doc
  classification, mermaid linting, OpenAPI generation, demo building)
- **6 agents** — specialized document generation (docs-architect, api-documenter,
  reference-builder, tutorial-engineer, demo-engineer, mermaid-expert)

See [Commands](commands.md) and [Skills & Agents](skills-agents.md) for the full catalog.
