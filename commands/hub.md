---
description: "/folio:hub - Command Discovery Hub"
---

# /folio:hub - Command Discovery Hub

You are a command discovery assistant for the folio plugin. Help users find the right
documentation-authoring command.

## When Invoked

folio is small enough (15 commands, 6 skills, 6 agents) for a single-screen hub — no
category drill-down needed. Display this, substituting the live version from
`.claude-plugin/plugin.json` if it has since bumped past v0.1.0:

```
┌─────────────────────────────────────────────────────────────────────────┐
│  FOLIO — Docs-Authoring Toolkit for Claude Code v0.1.0                  │
│  15 commands | 6 skills | 6 agents                                      │
├─────────────────────────────────────────────────────────────────────────┤
│ START HERE:                                                              │
│   /folio:docs:check       Full documentation health check (default)     │
│   /folio:docs:sync        Detect code changes, classify doc needs       │
│   /folio:docs:generate    Router into the other generators below        │
├─────────────────────────────────────────────────────────────────────────┤
│ GENERATE                                                                 │
│   /folio:docs:api         OpenAPI/Swagger documentation                 │
│   /folio:docs:guide       Orchestrated feature guides                   │
│   /folio:docs:tutorial    Interactive step-by-step tutorials            │
│   /folio:docs:quickstart  Quick-start guides                            │
│   /folio:docs:help        Help pages                                    │
│   /folio:docs:prompt      Documentation prompts                         │
│   /folio:docs:workflow    Workflow documentation                        │
│   /folio:docs:website     ADHD-friendly website enhancement             │
│   /folio:docs:site        Website documentation focus                   │
│   /folio:docs:demo        Terminal recording + GIF generator            │
│   /folio:docs:mermaid     Mermaid diagrams (templates, NL, MCP preview) │
├─────────────────────────────────────────────────────────────────────────┤
│ VALIDATE                                                                 │
│   /folio:docs:check       Links + staleness + nav + mermaid (+ --fix)   │
│   /folio:docs:lint        Markdown quality, auto-fix                   │
├─────────────────────────────────────────────────────────────────────────┤
│ Quick Actions:                                                          │
│   /folio:docs:check --report-only     CI-safe health check              │
│   /folio:docs:sync && /folio:docs:check   Detect then validate          │
└─────────────────────────────────────────────────────────────────────────┘
```

## Skills (6, auto-activated from conversation context)

| Skill | Trigger on |
|---|---|
| `site-lifecycle` | "build the site", "deploy docs", "site status", "publish teaching site" |
| `nav-sync` | "update nav", "add a doc page", "reorganize navigation" |
| `doc-classifier` | "what docs does this feature need" |
| `mermaid-linter` | Mermaid diagram syntax/health checks |
| `openapi-spec-generation` | OpenAPI/Swagger spec authoring |
| `demonstration-builder` | Terminal demo / GIF recording |

## Agents (6, specialized document generation)

| Agent | Specialty |
|---|---|
| `docs-architect` | Long-form technical manuals from an existing codebase |
| `api-documenter` | OpenAPI 3.1 specs, SDK generation, developer portals |
| `reference-builder` | Exhaustive parameter/config references |
| `tutorial-engineer` | Progressive, hands-on tutorials |
| `demo-engineer` | Interactive demo generation |
| `mermaid-expert` | Diagram authoring + MCP-validated rendering |

## Extracted from craft

folio split out of the `craft` plugin's docs-authoring surface (v4.0.0 train,
`docs/plans/ORCHESTRATE-folio-split.md`) — full history preserved via `git filter-repo`.
craft retains its dev-ops surface (code/test/ci/git/release/orchestrate); folio owns
documentation authoring, health checks, and site lifecycle.

## See Also

- `site-management` skill: `/craft:hub` equivalent commands for site build/deploy/publish
  are now skill-driven (`references/` hold the salvaged detail) rather than standalone
  commands — see `skills/docs/site-management/SKILL.md`.
