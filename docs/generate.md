# Generate

Eleven commands, one job each: produce a specific kind of documentation content. If you're not
sure which one you want, `/folio:docs:generate` or `/folio:do "<description>"` will route for
you — this page is for when you want to pick directly.

## By what you're documenting

| You're documenting... | Command |
|---|---|
| A REST/HTTP API | `/folio:docs:api` — OpenAPI/Swagger spec generation |
| A whole feature, end to end | `/folio:docs:guide` — orchestrated, multi-section guide |
| A process a user follows step by step | `/folio:docs:tutorial` — interactive, hands-on |
| "Get started in 5 minutes" | `/folio:docs:quickstart` |
| A single command or flag | `/folio:docs:help` — standalone help page |
| A reusable prompt template | `/folio:docs:prompt` |
| An internal process (CI, release, etc.) | `/folio:docs:workflow` |
| Your project's public website | `/folio:docs:website` (ADHD-friendly enhancement pass) or
  `/folio:docs:site` (documentation-specific focus) |
| A terminal session, for a README/demo | `/folio:docs:demo` — recording + GIF generation |
| A flowchart, sequence, or architecture diagram | `/folio:docs:mermaid` |

## `guide` vs `tutorial` vs `quickstart` — the one distinction people miss

These three all produce "how do I use this" content, but at different depths:

- **`quickstart`** — the shortest path to a working example. Skips explanation.
- **`tutorial`** — a full learning path: explains *why* at each step, not just *what to type*.
- **`guide`** — the most comprehensive: orchestrates multiple sections (setup, usage, edge
  cases, troubleshooting) for a whole feature, not just one task.

If you only have time to write one, write the `quickstart` first — it's the one most users
actually read.

## `website` vs `site` — the other one

Both touch your project's public-facing site, but `website` is a broad enhancement pass
(navigation, readability, ADHD-friendly formatting) applied across existing pages, while `site`
is scoped specifically to documentation-focused site concerns (nav structure, build config).
If you're not sure, start with `/folio:docs:check` (see [Validate](validate.md)) — it'll tell you
what's actually broken before you reach for either generator.
