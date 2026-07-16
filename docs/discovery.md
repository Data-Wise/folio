# Discovery

Four commands, all pointed at the same problem: **finding the right command** rather than
generating anything themselves.

## `/folio:hub` — browse everything

Prints a single-screen listing of all 17 commands, grouped by GENERATE / VALIDATE, plus folio's
6 skills and 6 agents. Use this when you want to see the whole surface at once, or don't know
what folio can do yet.

```
/folio:hub
```

## `/folio:do` — describe what you want

A thin keyword-table dispatcher: give it a natural-language description, and it matches against
a flat routing table (no complexity scoring, no orchestration — folio's surface is small enough
that a lookup table is the whole mechanism) and routes to the matching command. If nothing (or
more than one thing) matches confidently, it falls back to `/folio:hub` instead of guessing.

```
/folio:do "check for broken links"        → /folio:docs:check
/folio:do "write a tutorial for the CLI"  → /folio:docs:tutorial
/folio:do check                            → /folio:docs:check (exact-name match)
```

Use `/folio:do "<task>" --dry-run` to see which command would be invoked without invoking it.

## `/folio:docs:sync` — what do I need, given recent changes?

Detects code changes (via `git diff`/`git log`) and classifies what documentation work they
imply — new API surface needs `/folio:docs:api`, a new feature needs a guide or tutorial, etc.
This is the command to run right after a code change, before deciding which generator to invoke.

```
/folio:docs:sync                  # classify against the last 10 commits (default)
/folio:docs:sync --since HEAD~5   # narrower range
```

## `/folio:docs:generate` — router into the generators

A router specifically over the [Generate](generate.md) family (the 11 commands that produce new
documentation content) — narrower than `/folio:do`, useful once you already know you want to
*generate* something and just need help picking which of the 11.

## Which one do I actually want?

| You know... | Use |
|---|---|
| Nothing yet — just exploring | `/folio:hub` |
| Roughly what you want, in plain English | `/folio:do "<description>"` |
| You just changed code, unsure what docs are stale | `/folio:docs:sync` |
| You want to generate something, unsure which generator | `/folio:docs:generate` |
| Exactly which command you want | Call it directly — skip discovery entirely |
