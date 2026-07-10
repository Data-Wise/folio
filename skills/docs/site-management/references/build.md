---
title: Build — salvaged detail (from deprecated /craft:site:build)
---

# Build — additional detail

Content from the deprecated `/craft:site:build` command not already covered by the skill's
"build" section.

## Teaching-mode before/after output (exact format)

Before build, when a `.flow/teach-config.yml` (or `_quarto.yml` teaching metadata) is detected:

```
┌─────────────────────────────────────────────┐
│ 📚 TEACHING MODE DETECTED                   │
├─────────────────────────────────────────────┤
│ Course: STAT 545 (Spring 2026)              │
│ Progress: Week 5/16 (31% complete)          │
│                                             │
│ 🔍 VALIDATION:                              │
│ ✅ Syllabus sections: complete              │
│ ✅ Schedule: 16/16 weeks                    │
│ ⚠️  Assignments: 2/3 found (hw-3 missing)   │
│                                             │
│ Status: Ready to build (warnings only)      │
└─────────────────────────────────────────────┘
```

After a successful build:

```
┌─────────────────────────────────────────────┐
│ ✅ BUILD COMPLETE                           │
├─────────────────────────────────────────────┤
│ 🌐 DEPLOYMENT URLS:                         │
│ • Draft: https://draft.example.com          │
│ • Production: https://course.example.com    │
│                                             │
│ 📊 SEMESTER PROGRESS:                       │
│ Week 5/16 · 31% complete                    │
│ Next: Spring Break in 18 days               │
└─────────────────────────────────────────────┘
```

Validation runs before build and warns (never blocks) on: missing syllabus sections, incomplete
schedule, missing assignment files. Teaching-context failures never fail the build itself — all
wrapped defensively so a broken teach-config degrades to a silent skip, not an error.

## Dry-run output (exact format)

```
┌───────────────────────────────────────────────────────────────┐
│ 🔍 DRY RUN: Build Documentation Site                           │
├───────────────────────────────────────────────────────────────┤
│ ✓ Detection:   Type: MkDocs · Config: mkdocs.yml · Theme: material │
│ ✓ Build Plan:  Command: mkdocs build · Output: site/            │
│                Estimated files: ~450 · Estimated size: ~2.3 MB  │
└───────────────────────────────────────────────────────────────┘
```

## Error handling — fuller "common issues" list

Beyond the skill's "YAML syntax, missing nav targets, broken includes": also check for **missing
dependencies** (framework CLI not installed) and **missing referenced files** (image/include
paths that don't resolve) before assuming a YAML/link problem.

## Implementation note

Original craft implementation hooked teaching-mode context into build via 4 helper modules
(`detect_teaching_mode`, `teach_config`, `teaching_validation`, `semester_progress`) called
before/after the framework's native build command, each wrapped in try/except so a teaching-
context failure degrades to a stderr warning rather than failing the build. Not reproduced here
verbatim (craft-specific module paths) — re-implement against folio's own script layout if/when
teaching-mode build integration is built for folio.
