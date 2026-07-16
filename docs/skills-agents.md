# Skills & Agents

## Skills (6, auto-activate from conversation context)

| Skill | Location | Trigger on |
|---|---|---|
| `site-lifecycle` | `skills/docs/site-management/` | "build the site", "deploy docs", "site status", "publish teaching site" |
| `nav-sync` | `skills/docs/navigation/` | "update nav", "add a doc page", "reorganize navigation" |
| `doc-classifier` | `skills/docs/doc-classifier/` | "what docs does this feature need" |
| `mermaid-linter` | `skills/docs/mermaid-linter/` | Mermaid diagram syntax/health checks |
| `openapi-spec-generation` | `skills/docs/openapi-spec-generation/` | OpenAPI/Swagger spec authoring |
| `demonstration-builder` | `skills/code/demonstration-builder/` | Terminal demo / GIF recording |

## Agents (6, specialized document generation)

| Agent | Specialty |
|---|---|
| `docs-architect` | Long-form technical manuals from an existing codebase |
| `api-documenter` | OpenAPI 3.1 specs, SDK generation, developer portals |
| `reference-builder` | Exhaustive parameter/config references |
| `tutorial-engineer` | Progressive, hands-on tutorials |
| `demo-engineer` | Interactive demo generation |
| `mermaid-expert` | Diagram authoring + MCP-validated rendering |
