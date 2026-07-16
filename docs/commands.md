# Commands (17)

See [Discovery](discovery.md), [Generate](generate.md), and [Validate](validate.md) for
per-family usage guidance — this page is the flat reference listing.

## Discovery

| Command | Description |
|---|---|
| `/folio:hub` | Command discovery hub — single-screen listing of all 17 commands |
| `/folio:do` | Thin keyword-table dispatcher — routes a natural-language request to the right command |
| `/folio:docs:generate` | Router into the generators below |
| `/folio:docs:sync` | Detect code changes, classify documentation needs |

## Generate

| Command | Description |
|---|---|
| `/folio:docs:api` | OpenAPI/Swagger documentation |
| `/folio:docs:guide` | Orchestrated feature guides |
| `/folio:docs:tutorial` | Interactive step-by-step tutorials |
| `/folio:docs:quickstart` | Quick-start guides |
| `/folio:docs:help` | Help pages |
| `/folio:docs:prompt` | Documentation prompts |
| `/folio:docs:workflow` | Workflow documentation |
| `/folio:docs:website` | ADHD-friendly website enhancement |
| `/folio:docs:site` | Website documentation focus |
| `/folio:docs:demo` | Terminal recording + GIF generator |
| `/folio:docs:mermaid` | Mermaid diagrams (templates, NL creation, MCP preview) |

## Validate

| Command | Description |
|---|---|
| `/folio:docs:check` | Links + staleness + navigation + mermaid health (+ `--fix`) |
| `/folio:docs:lint` | Markdown quality and error detection with auto-fix |

## Site lifecycle (skill-driven, not standalone commands)

Site build/preview/deploy/publish/status/update moved to the `site-management` skill
(`skills/docs/site-management/SKILL.md`) during the folio split — see its `references/` for
the detailed formats salvaged from the original standalone commands.
