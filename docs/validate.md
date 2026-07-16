# Validate

Two commands, both about finding problems in documentation that already exists — as opposed to
the [Generate](generate.md) family, which produces new content.

## `/folio:docs:check` — the full health check

Runs by default when invoked with no flags: broken links (internal and external), stale docs
(content not updated when the code it describes changed), navigation consistency (`mkdocs.yml`
entries actually resolve), and Mermaid diagram syntax pre-checks. Auto-fixes what's safe to
auto-fix, and reports the rest for a human to look at.

```
/folio:docs:check                  # full check, auto-fix safe issues
/folio:docs:check --dry-run        # preview what would be checked/fixed, change nothing
/folio:docs:check --report-only    # CI-safe: report findings, never write to disk
```

Run this first when you're not sure what's wrong — it's the closest thing folio has to "just
tell me what needs attention."

## `/folio:docs:lint` — markdown quality specifically

Narrower than `check`: markdown formatting and quality issues (heading hierarchy, list
formatting, line length, etc.), with auto-fix for the mechanical stuff. Use this when you know
the *content* is right but want the *formatting* cleaned up — `check` won't catch pure style
issues, and `lint` won't catch broken links or staleness.

```
/folio:docs:lint
```

## Which one do I want?

| Symptom | Command |
|---|---|
| "Something in the docs feels stale or broken, not sure what" | `/folio:docs:check` |
| "The content's right but the markdown looks messy" | `/folio:docs:lint` |
| Pre-commit / CI gate | `/folio:docs:check --report-only` |
