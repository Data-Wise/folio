---
title: Publish — salvaged detail (from deprecated /craft:site:publish)
---

# Publish — additional detail

Content from the deprecated `/craft:site:publish` command not already covered by the skill's
"publish" section (Phase 3 — Ship). The skill states the two-stage draft→production intent; this
file preserves the exact teaching-mode safety workflow, output formats, config schema, and error
handling.

## 5-step teaching-mode safety workflow (exact sequence)

For teaching projects (`.flow/teach-config.yml` detected), publish runs a rollback-safe sequence:

### Step 1 — Validate draft branch

Checks teaching content completeness (syllabus sections, schedule weeks, assignment files):

```
============================================================
TEACHING CONTENT VALIDATION: ❌ BLOCKED
============================================================

🚫 ERRORS (must fix before publishing):
  1. Syllabus missing required sections: policies, objectives
  2. Schedule has incomplete weeks (no content): Week 2, 4

⚠️  WARNINGS (recommended to fix):
  1. Missing assignment files: HW 2

📋 DETAILED CHECKS:
  [✓] Syllabus: grading
  [✗] Syllabus: policies
  [✓] Schedule: exists
  [✗] Schedule: 2/4 weeks complete
  [✗] Assignments: 2/3 found

============================================================
Summary: 3/7 checks passed
Status: 2 error(s) blocking publish ❌
============================================================
```

Errors → prompt to continue or fix first. Warnings only → shown, proceeds.

### Step 2 — Preview changes (categorized diff)

```
┌─────────────────────────────────────────────┐
│ 📋 PUBLISH PREVIEW                          │
├─────────────────────────────────────────────┤
│ CRITICAL CHANGES:                           │
│ ⚠️  syllabus/index.qmd      +15  -3        │
│ ⚠️  schedule.qmd            +42  -8        │
│ CONTENT CHANGES:                            │
│ ✓  lectures/week-01.qmd     +120 -0        │
│ OTHER CHANGES:                              │
│    _quarto.yml              +2   -1        │
│ Summary: 8 files, +335 lines, -14 lines    │
└─────────────────────────────────────────────┘
```

File categories: **Critical** = `syllabus*`, `schedule*`, `assignments/` · **Content** =
`lectures/`, `readings/`, `resources/` · **Other** = everything else.

### Step 3 — Confirm (AskUserQuestion)

1. **Yes — Merge and deploy (Recommended)**
2. **Preview full diff first** — show `git diff`, loop back
3. **Cancel** — abort, preserve state

### Step 4 — Execute (rollback-safe)

```bash
git branch production-backup-<timestamp>   # 1. backup
git checkout production                     # 2. checkout production
git merge draft --ff-only                   # 3. ff-merge (conflict → abort, changes safe)
git push origin production                  # 4. push (handles auth/network errors)
# 5. verify: HTTP GET gh_pages_url from teach-config.yml, 5-min timeout, non-blocking
# 6. rollback on merge/push failure:
git reset --hard production-backup-<timestamp>   # backup branch preserved
```

### Step 5 — Cleanup + completion

```
✅ PUBLISH SUCCESSFUL
🌐 Live Site: https://data-wise.github.io/stat-440/
📊 Changes Published: 8 files, +335 / -14
💡 Next: review live site · /craft:git:clean · continue on draft
⏱ Deployment may take 1-2 minutes to propagate.
```

## Non-teaching mode

Detect framework → preview → confirm → deploy (`quarto publish gh-pages` / `mkdocs gh-deploy`).

## teach-config.yml schema

```yaml
course: { number: "STAT 440", title: "Regression Analysis", semester: "Spring", year: 2026 }
dates:
  start: "2026-01-19"
  end: "2026-05-08"
  breaks: [ { name: "Spring Break", start: "2026-03-16", end: "2026-03-20" } ]
deployment:
  production_branch: "production"   # students see this
  draft_branch: "draft"             # instructors work here
  gh_pages_url: "https://data-wise.github.io/stat-440/"
validation:
  required_sections: [ grading, policies, objectives, schedule ]
  strict_mode: true
```

## Error handling (exact messages)

- **Validation errors** → `❌ BLOCKED` with numbered errors; fix or `--skip-validation` to override.
- **Merge conflicts** → `❌ MERGE FAILED: Cannot fast-forward` + manual-resolution steps; changes safe.
- **Network/push** → `❌ PUSH FAILED` (e.g. `Permission denied (publickey)`); local changes rolled
  back, backup branch preserved.

## Undo a publish

Backup branch is preserved: `git checkout production && git reset --hard production-backup-<timestamp>`
then force-push.
