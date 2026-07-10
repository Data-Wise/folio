---
title: Check — salvaged detail (from deprecated /craft:site:check)
---

# Check — additional detail

Content from the deprecated `/craft:site:check` command not already covered by the skill's
"check" section.

## Pre-build lint phase (run before link/structure checks)

Lint all markdown first — catches formatting issues that cause rendering problems before
spending time on link/structure validation. Blocks deployment on failure (exit 1):

```
Phase 0: Pre-Build Lint
✗ 3 markdown issues found
  - docs/guide.md:21 [MD032] Missing blank line
  - docs/api.md:45 [MD040] Missing language tag
  - README.md:8 [MD034] Bare URL
BLOCKING: Lint issues must be fixed before deployment
```

## Per-framework check commands

| Framework | Command |
|---|---|
| MkDocs | `linkchecker http://localhost:8000` (if installed) or `mkdocs build --strict` |
| pkgdown | `pkgdown::check_pkgdown()` |
| Quarto | `quarto render --strict` |

## Full validation report format

```
📋 DOCUMENTATION VALIDATION REPORT
Site Type: MkDocs

✅ PASSED: Build: No errors · Links: All internal links valid (450 checked)
           Structure: All nav items have files · Images: All 23 images found
⚠️ WARNINGS: Unused file: docs/archive/old-guide.md (not in nav)
             Long page: docs/reference.md (>5000 lines)
❌ ERRORS: Broken link: docs/guide.md → missing.md (line 45)
           Missing file: docs/api.md (referenced in mkdocs.yml nav)

SUMMARY: 4 passed, 2 warnings, 2 errors
```

## Common issues and fixes

| Issue | Fix |
|-------|-----|
| Broken internal link | Check file path and extension (.md) |
| Missing nav file | Create the file or remove from nav |
| Image not found | Check path is relative to docs/ |
| Build warning | Usually safe to ignore, but review |
| Orphaned page | Add to navigation or delete if unused |

## Exit codes

`0` no errors · `1` errors found (broken links, missing files) · `2` build failed.
