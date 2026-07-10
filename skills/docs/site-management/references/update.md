---
title: Update — salvaged detail (from deprecated /craft:site:update)
---

# Update — additional detail

Content from the deprecated `/craft:site:update` command not already covered by the skill's
"update" section (Phase 3 — Ship). The skill states the detect→classify→update→modes intent;
this file preserves the change-detection matrix, the badge-synchronization step, and the exact
output formats.

## Update detection matrix

Maps a code change to the docs that must follow:

| Change Type | Files Changed | Docs to Update |
|-------------|---------------|----------------|
| New CLI command | `src/*/cli/*.py` | REFCARD, commands.md |
| New feature | `src/**/*.py` | index.md features, guide |
| Config change | `pyproject.toml`, `package.json` | installation.md, config.md |
| Version bump | Config files | All version references |
| New doc file | `docs/*.md` | mkdocs.yml navigation |
| API change | `src/*/api/*` | api.md, reference |

## Step 3.5 — Badge synchronization

After content updates, sync version/CI/coverage badges across `README.md` and `docs/index.md`
(non-blocking — a failure warns and continues):

```python
from utils.badge_syncer import BadgeSyncer
syncer = BadgeSyncer(project_root=Path.cwd())
mismatches = syncer.sync_badges(
    files=['README.md', 'docs/index.md'],
    auto_confirm=False,          # always prompt
    calculate_coverage=True,
)
```

| Badge Type | Generated From | Files Updated |
|------------|----------------|---------------|
| Version | plugin.json / package.json / pyproject.toml | README.md, docs/index.md |
| CI Status | `.github/workflows/*.yml` | README.md, docs/index.md |
| Docs Coverage | `.STATUS` "Documentation: XX%" | README.md, docs/index.md |

## Output formats

**Analyze** (Step 1) and **Results** (Step 5) render boxed summaries listing recent code changes,
docs last-updated, files to update (`✓` update / `○` unchanged), and next steps
(`mkdocs serve` / deploy / status).

**Preview / `--dry-run` (`-n`)** shows per-file line-level additions without writing:

```
🔍 PREVIEW MODE (no changes made)
docs/REFCARD.md:
  Line 45: + | `ait sessions live` | Show active sessions |
docs/index.md:
  Line 3: Version badge 0.3.6 → 0.3.7
Run without --preview to apply changes.
```

`--preview` (legacy) and `--dry-run` / `-n` (standardized) are aliases — same behavior.

## Full mode (`full`)

Regenerates everything regardless of detected changes: all command refs, config docs, version
references, code examples, navigation, and validation.
