---
description: Documentation health check (links, staleness, navigation)
category: docs
arguments:
  - name: fix
    description: Auto-fix safe issues
    required: false
    default: false
  - name: dry-run
    description: Preview checks without fixing
    required: false
    default: false
    alias: -n
---

# /folio:docs:check - Documentation Health Check

You are a documentation health checker. Validate, fix, and report on documentation status.

## Purpose

**Full documentation health check by default:**

- Broken links (internal and external)
- Stale docs (not updated when code changed)
- Navigation consistency (mkdocs.yml)
- Mermaid diagram validation (syntax pre-checks)
- Auto-fix safe issues
- Report what needs human attention

## Philosophy

> **"Just run it. It fixes what it can and tells you what needs attention."**

## Usage

```bash
# DEFAULT: Full check cycle (links + stale + nav + mermaid + auto-fix)
/folio:docs:check

# LIMIT SCOPE
/folio:docs:check --report-only       # No auto-fix, just report
/folio:docs:check --links-only        # Just broken links (fast)
/folio:docs:check --no-stale          # Skip stale detection

# CI MODE (use in pipelines)
/folio:docs:check --report-only       # Safe for CI - no modifications
```

## When Invoked

### Step 1: Scan Documentation

```bash
# Find all markdown files
find docs/ -name "*.md" -type f

# Find README and other root docs
ls *.md CLAUDE.md 2>/dev/null

# Check mkdocs.yml for nav entries
cat mkdocs.yml | grep -A 100 "nav:"
```

### Step 2: Run Full Check Cycle

**Phase 1: Link Validation (with .linkcheck-ignore support)**

```
🔗 CHECKING LINKS...

Internal links:
  ✓ docs/index.md → docs/guide/overview.md
  ✓ docs/guide/overview.md → docs/reference/api.md
  ✗ docs/guide/setup.md → docs/config.md (not found) [CRITICAL]
  ⚠ docs/test-violations.md → nonexistent.md (expected - Test Files)

External links:
  ✓ README.md → https://github.com/user/repo
  ⚠ README.md → https://old-domain.com/docs (404)

Summary: 45 internal (1 critical, 1 expected), 12 external (1 broken)
```

**Note**: Critical broken links cause exit code 1. Expected broken links (documented in
`.linkcheck-ignore`) are shown as warnings but don't block CI — see ".linkcheck-ignore Support"
below for the format.

**Phase 2: Stale Detection**

```
📅 CHECKING STALE DOCS...

Comparing doc modification dates with related code changes...

  ⚠ docs/guide/auth.md
    Last updated: 45 days ago
    Related code changed: 12 days ago (src/auth/)

  ⚠ docs/reference/api.md
    Last updated: 32 days ago
    Related code changed: 5 days ago (src/api/)

Summary: 2 docs may be stale
```

**Phase 3: Navigation Consistency**

```
📁 CHECKING NAVIGATION...

mkdocs.yml nav entries:
  ✓ guide/quickstart.md exists
  ✓ guide/installation.md exists
  ✗ guide/configuration.md missing (in nav but file not found)

Orphan files (not in nav):
  ⚠ docs/guide/advanced-tips.md

Summary: 1 missing, 1 orphan
```

**Phase 4: Auto-Fix Safe Issues**

```
🔧 AUTO-FIXING...

  ✓ Fixed: docs/guide/setup.md
    Link updated: docs/config.md → docs/reference/configuration.md

  ✓ Fixed: mkdocs.yml
    Added missing nav entry: guide/advanced-tips.md

Auto-fixed: 2 issues
```

**Phase 5: Mermaid Validation**

```
🔷 CHECKING MERMAID DIAGRAMS...

Running local regex pre-checks on all mermaid blocks...

  ✓ 184 blocks scanned across 95 files
  ✓ 0 errors (leading-slash, lowercase-end)
  ⚠ 73 warnings (deprecated graph, br-tags, unquoted-colons)

  Mermaid Health Score: 82/100 (Warning)
    Syntax validity:    100.0%
    Best practices:     40.8%
    Rendering success:  100.0%

Mermaid: PASS (0 errors, health score >= 80)
```

**Health score thresholds:**

| Score | Level | Release Gate |
|-------|-------|-------------|
| >= 90 | Good | Pass |
| >= 80 | Warning | Pass (default threshold) |
| < 80 | Fail | Blocked |

**How to run this phase:**

```bash
# Extract and validate all mermaid blocks
python3 scripts/mermaid-validate.py docs/ commands/ skills/

# With health score
python3 scripts/mermaid-validate.py docs/ --health-score

# Release gate check (exit 1 if score < 80)
python3 scripts/mermaid-validate.py docs/ --gate

# Custom threshold
python3 scripts/mermaid-validate.py docs/ --gate 90

# Errors-only mode (for CI)
python3 scripts/mermaid-validate.py docs/ --errors-only

# JSON output for parsing
python3 scripts/mermaid-validate.py docs/ --json
```

**Error-level rules** (block commit/deploy):

| Rule | Pattern | Why |
|------|---------|-----|
| `leading-slash` | `[/text]` in labels | Misinterpreted as parallelogram shape |
| `lowercase-end` | `[end]` in labels | Conflicts with Mermaid `end` keyword |

**Warning-level rules** (reported, don't block):

| Rule | Pattern | Why |
|------|---------|-----|
| `unquoted-colon` | `[a:b]` in labels | May cause parsing issues |
| `br-tag` | `<br/>` in blocks | Style: prefer Mermaid line break syntax |
| `deprecated-graph` | `graph TB` directive | Style: prefer `flowchart` |

### Step 3: Show Summary Report

```
┌─────────────────────────────────────────────────────────────┐
│ /folio:docs:check                                           │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│ ✓ Fixed: 2 broken links (auto-fixed)                        │
│ ✓ Fixed: 1 nav entry (auto-added)                           │
│                                                             │
│ ⚠ Stale: 2 docs haven't been updated in 30+ days            │
│   - docs/guide/auth.md (45 days, code changed)              │
│   - docs/reference/api.md (32 days, code changed)           │
│                                                             │
│ ✗ Manual: 1 issue needs attention                           │
│   - External link 404: README.md:120                        │
│     https://old-domain.com/docs                             │
│                                                             │
│ ─────────────────────────────────────────────────────────── │
│                                                             │
│ Mermaid: 184 blocks OK, 0 errors                             │
│ Summary: 3 fixed, 2 stale, 1 manual                         │
│                                                             │
│ Next steps:                                                 │
│   → Update stale docs: /craft:docs:update                   │
│   → Fix manual issues: edit README.md:120                   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Deep Staleness Check (`--deep`)

The `--deep` flag triggers Phases 6-9 of the staleness detection system, running `scripts/docs-staleness-check.sh` as part of the check cycle.

```bash
# Run full check with deep staleness detection
/folio:docs:check --deep

# Deep check in CI mode (no interactive prompts)
/folio:docs:check --deep --report-only

# Deep check with auto-fix
/folio:docs:check --deep --fix
```

**Phases triggered by `--deep`:**

| Phase | Name | What It Checks |
|-------|------|---------------|
| 6 | Nav Completeness | Files missing from `mkdocs.yml` nav; nav entries pointing to missing files |
| 7 | Count Consistency | Stale command/skill/agent counts across all docs |
| 8 | Skill/Agent Coverage | Undocumented skills and agents |
| 9 | Cross-Doc Freshness | Stale version strings, count drift in cross-references |

**Traffic light output:** GREEN (clean), YELLOW (warnings), RED (errors). RED blocks releases; YELLOW is reported but non-blocking.

**Exclusion config:** `scripts/config/exclusions.txt` -- shared with `post-release-sweep.sh`. Supports whole-file, directory, and pattern-level exclusions.

See [Docs Staleness Quick Reference](../../docs/reference/REFCARD-DOCS-STALENESS.md) for full details.

---

## Check Types

### Link Validation

| Type | Check | Auto-Fix |
|------|-------|----------|
| Internal `.md` | File exists | ✓ Update path if found elsewhere |
| Internal `#anchor` | Heading exists | ✗ Report only |
| External `http` | Returns 200 | ✗ Report only |
| Image | File exists | ✓ Update path if found elsewhere |

### Stale Detection

| Criteria | Threshold | Action |
|----------|-----------|--------|
| Doc not updated | 30+ days | ⚠ Warning |
| Related code changed | After doc update | ⚠ Warning |
| Both conditions | - | ⚠⚠ High priority |

**Related code detection:**

- `docs/guide/auth.md` → `src/auth/`, `src/**/auth*`
- `docs/reference/api.md` → `src/api/`, `src/**/api*`
- Filename-based matching

### Navigation Consistency

| Check | Auto-Fix |
|-------|----------|
| File in nav but missing | ✗ Report (may be intentional) |
| File exists but not in nav | ✓ Add to appropriate section |
| Nav order issues | ✗ Report only |

## Output Modes

### Default (Interactive)

Full visual output with boxes, colors, and actionable suggestions.

### JSON (`--json`)

```json
{
  "status": "issues_found",
  "fixed": {
    "links": 2,
    "nav": 1
  },
  "stale": [
    {"file": "docs/guide/auth.md", "days": 45, "code_changed": true}
  ],
  "manual": [
    {"type": "external_link", "file": "README.md", "line": 120, "url": "https://old-domain.com/docs"}
  ]
}
```

### CI Mode (`--report-only`)

```
DOCS CHECK: 3 issues found

BROKEN LINKS (1):
  - README.md:120 → https://old-domain.com/docs (404)

STALE DOCS (2):
  - docs/guide/auth.md (45 days)
  - docs/reference/api.md (32 days)

Exit code: 1
```

## .linkcheck-ignore Support

Absorbed from the retired `/folio:docs:check-links` command (folded here 2026-07 — this file now
owns the full links story; the standalone command was redundant with this one).

Ignore expected broken links via a `.linkcheck-ignore` file in the project root — document known
issues (test fixtures, gitignored brainstorm references) without them blocking CI.

```markdown
# Known Broken Links

### Test Files (Intentional)
File: `docs/test-violations.md`
- Purpose: Test data for validation

### Brainstorm References (Gitignored)
Files with broken links:
- `docs/specs/SPEC-feature-a.md`
Targets: `docs/brainstorm/*.md` (gitignored)
```

| Pattern | Example | Matches |
|---------|---------|---------|
| Exact | `File: docs/test.md` | Exact file path only |
| Glob | `Files: docs/specs/*.md` | All files matching pattern |
| Any target | No `Target:` line | All broken links in file |
| Specific target | `Target: ../README.md` | Only links to that target |
| Glob target | `Targets: docs/brainstorm/*.md` | Links matching pattern |

**Behavior:** broken link NOT in `.linkcheck-ignore` → critical (exit 1). Broken link IN the
file → expected (warning, exit 0). File missing entirely → all broken links treated as critical.
Paths normalize both absolute and relative forms; matching is case-sensitive.

## Anchor Validation (heading-link checks)

Headings are normalized for `#anchor` matching: lowercase, spaces → dashes, non-alphanumerics
stripped (`"API Reference"` → `#api-reference`).

```bash
extract_headings() {
  grep -E '^#{1,6} ' "$1" | sed 's/^#* //' | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/[^a-z0-9-]//g'
}
```

Cross-file (`file.md#heading`) and same-file (`#heading`) anchors both validated this way.

## VS Code Integration (clickable output)

`--verbose` output uses `file:line:col` format so broken-link lines are clickable in an
integrated terminal:

```
docs/index.md:34:10: [Configuration](/docs/config.md) → File not found
docs/guide/setup.md:15:5: [missing.md](missing.md) → File not found
```

## Flags Reference

| Flag | Effect |
|------|--------|
| (none) | Full check: links + stale + nav + mermaid + auto-fix |
| `--no-mermaid` | Skip mermaid validation |
| `--mermaid-gate N` | Fail if mermaid health score < N (default 80) |
| `--report-only` | No auto-fix, just report (CI-safe) |
| `--links-only` | Just broken links (fast) |
| `--no-stale` | Skip stale detection |
| `--no-nav` | Skip navigation check |
| `--json` | JSON output |
| `--verbose` | Detailed output |

## Integration

**Called by:**

- `/craft:docs:update` - Runs check after generating docs

**Works with:**

- `/folio:docs:sync` - Detection pairs with check
- `/folio:docs:guide` - Validate generated guides
- `/craft:ci:validate` - Part of CI pipeline
- `/craft:site:deploy` - Health score gates deployment (>= 80)
- `/craft:check --for release` - Includes mermaid health in pre-flight

## CI Pipeline Usage

```yaml
# .github/workflows/docs.yml
- name: Check Documentation
  run: |
    # Use --report-only in CI (no auto-modifications)
    claude "/folio:docs:check --report-only"
```

## Examples

```bash
# Daily workflow: just run it
/folio:docs:check
# → Fixes what it can, reports the rest

# Before PR: quick link check
/folio:docs:check --links-only
# → Fast, just broken links

# CI pipeline: report only
/folio:docs:check --report-only
# → No changes, exit code for CI

# Full report for review
/folio:docs:check --report-only --verbose
# → Detailed report, no changes
```

## Dry-Run Mode

```
┌───────────────────────────────────────────────────────────────┐
│ 🔍 DRY RUN: Documentation Health Check                         │
├───────────────────────────────────────────────────────────────┤
│                                                               │
│ ✓ Checks to Perform:                                          │
│   1. Broken links (internal & external)                       │
│   2. Stale documentation detection                            │
│   3. Navigation consistency (mkdocs.yml)                      │
│   4. Spelling and grammar                                     │
│   5. Code block validation                                    │
│                                                               │
│ ✓ Files to Check:                                             │
│   - docs/*.md (~45 files)                                     │
│   - mkdocs.yml                                                │
│   - README.md                                                 │
│                                                               │
│ ⚠ Auto-fix Available:                                         │
│   • Use --fix to apply safe corrections                        │
│                                                               │
│ 📊 Summary: Read-only health check (5 validation types)        │
│                                                               │
├───────────────────────────────────────────────────────────────┤
│ Run without --dry-run to execute                              │
└───────────────────────────────────────────────────────────────┘
```

**Note**: This is a read-only check, so dry-run shows what will be validated.

## See Also

- `/craft:site:check` - Site validation
- Template: `templates/dry-run-pattern.md`
- `/folio:docs:api` - OpenAPI/Swagger documentation generator
- `/craft:docs:changelog` - Auto-update CHANGELOG.md based on git commits
- `/folio:docs:demo` - Terminal recording and GIF generator with dependency management
- `/folio:docs:help` - Help page generator
- `/folio:docs:lint` - Markdown quality and error detection with auto-fix
- `/craft:docs:nav-update` - Update mkdocs.yml navigation from directory structure
- `/folio:docs:prompt` - Generate documentation prompts
- `/folio:docs:quickstart` - Quick start generator
- `/folio:docs:site` - Website documentation focus
- `/folio:docs:tutorial` - Interactive tutorial generator
- `/folio:docs:website` - ADHD-friendly website enhancement
- `/folio:docs:workflow` - Workflow documentation generator
