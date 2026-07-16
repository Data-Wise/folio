---
title: nav-update — salvaged detail (from deprecated /craft:docs:nav-update)
---

# nav-update — additional detail

Content from the deprecated `/craft:docs:nav-update` command not already covered by the skill's
Mode 1 (Sync). The skill covers the sync algorithm, title inference, section detection, and orphan
handling; this file preserves the exact multi-section output formats those steps produce.

## Analysis output

```
📊 NAVIGATION ANALYSIS
Current nav entries: 24   Actual doc files: 28
New files not in nav:
  + docs/guide/opencode.md
  + docs/reference/mcp-commands.md
Files in nav but missing:
  - docs/deprecated/old-feature.md
Orphan files (exist but not in nav):
  ? docs/drafts/wip-feature.md
```

## Update plan output

```
📝 NAVIGATION UPDATE PLAN
Additions:
  Guide:     + opencode.md → "OpenCode Integration"
  Reference: + mcp-commands.md → "MCP Commands"
Removals:
  - deprecated/old-feature.md (file deleted)
Suggested nav structure:
  nav:
    - Guide:
      - OpenCode Integration: guide/opencode.md  # NEW
Apply changes? (y/n/edit)
```

## Result output

```
✅ NAVIGATION UPDATED  (mkdocs.yml)
Changes: + 4 added · - 1 removed · ~ 0 reorganized
Nav structure: Home (1) · Getting Started (2) · Guide (2) · Reference (3) · API (2) · Troubleshooting (1)
Total: 11 navigation entries
Next: preview → validate → commit
```

## Dry-run (`--dry-run` / `-n`)

```
🔍 DRY RUN: Update Navigation
✓ Detection: mkdocs.yml · docs/ · 45 markdown files
✓ Navigation Changes:
  - Add: docs/new-guide.md (missing from nav)
  - Remove: docs/old-api.md (file doesn't exist)
  - Reorder: Move "Installation" before "Quick Start"
📊 Summary: 3 navigation changes
Run without --dry-run to execute.
```
