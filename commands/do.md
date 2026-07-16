---
description: "/folio:do - Thin Dispatcher for folio's Docs Commands"
arguments:
  - name: task
    description: Natural language description of what you want to do, or an explicit command name
    required: true
  - name: dry-run
    description: Show which command would be invoked without invoking it
    required: false
    default: false
    alias: -n
---

# /folio:do - Universal Dispatcher

Route a natural-language request (or an explicit command name) to the right folio command.
folio is small (16 commands total) — this is a **lookup table, not a router**. There is no
complexity scoring, no orchestration mode, no branch-awareness, and no multi-step sequencing.
If a task needs more than one command, name each command to the user and let them invoke the
next one themselves.

## How It Works

1. Read `<task>`.
2. If it's already an exact command name (`check`, `docs:sync`, `/folio:docs:api`, etc.),
   match it directly — skip keyword matching.
3. Otherwise match `<task>`'s keywords against the table below, top to bottom, first hit wins.
4. **Zero or ambiguous matches** (matches 2+ commands equally, or matches none): don't guess —
   show `/folio:hub`'s command list and ask which one the user meant.
5. **Single match**: with `--dry-run`/`-n`, print the matched command and one-line reason, then
   stop. Otherwise, follow that command's own file (`commands/docs/<name>.md` or
   `commands/hub.md`) exactly as if the user had invoked it directly — do not re-implement or
   summarize its logic here.

## Routing Table

| Keywords in `<task>` | Routes to |
|---|---|
| health check, broken link, staleness, nav check, validate docs | `/folio:docs:check` |
| detect change, classify doc, what docs (do I/does this) need | `/folio:docs:sync` |
| generate docs (no more specific match below) | `/folio:docs:generate` |
| openapi, swagger, api docs, api reference | `/folio:docs:api` |
| guide, walkthrough, feature guide | `/folio:docs:guide` |
| tutorial, step-by-step, learn, onboarding | `/folio:docs:tutorial` |
| quickstart, quick start, getting started | `/folio:docs:quickstart` |
| help page, help doc | `/folio:docs:help` |
| doc prompt, documentation prompt, prompt template | `/folio:docs:prompt` |
| workflow doc, document the workflow | `/folio:docs:workflow` |
| website enhancement, adhd-friendly, improve website | `/folio:docs:website` |
| site doc, website documentation focus | `/folio:docs:site` |
| demo, gif, terminal recording, screen recording | `/folio:docs:demo` |
| diagram, mermaid, flowchart, sequence diagram, erd | `/folio:docs:mermaid` |
| lint, markdown quality, formatting | `/folio:docs:lint` |
| list commands, what can folio do, find a command, help me choose | `/folio:hub` |

## Dry-Run Mode

```
/folio:do "check for broken links" --dry-run

→ Matched: /folio:docs:check
  Reason: keyword "broken link"
  Run without --dry-run to execute.
```

## Ambiguous / No-Match Example

```
/folio:do "make some docs"

→ No confident single match ("make some docs" could mean check, sync, or generate).
  Showing /folio:hub so you can pick directly.
```

## Examples

```
/folio:do "check for broken links"        → /folio:docs:check
/folio:do "write a tutorial for the CLI"  → /folio:docs:tutorial
/folio:do "generate an openapi spec"      → /folio:docs:api
/folio:do "make a mermaid diagram"        → /folio:docs:mermaid
/folio:do check                            → /folio:docs:check (exact-name match)
```
