---
title: Status — salvaged detail (from deprecated /craft:site:status)
---

# Status — additional detail

Content from the deprecated `/craft:site:status` command not already covered by the skill's
"status" section (Phase 2 — Author). The skill lists what the dashboard shows; this file
preserves the exact dashboard formats, the health-score model (incl. Mermaid scoring), and the
freshness thresholds.

## Gather step (key probes)

Beyond framework/page-count/last-deploy, status probes **Mermaid config** (critical for diagram
rendering — Material for MkDocs renders Mermaid natively, no CDN needed):

```bash
grep -q "custom_fences" mkdocs.yml && echo "✅ custom_fences" || echo "❌ custom_fences missing"
grep -A3 "extra_javascript" mkdocs.yml | grep -q "mermaid" && echo "⚠️ mermaid CDN (unnecessary)"
grep -rq "\.mermaid" docs/stylesheets/ && echo "✅ Mermaid CSS" || echo "⚠️ No Mermaid CSS"
grep -r "^\`\`\`mermaid" docs/ | wc -l   # diagram count
```

## Full dashboard format

```
┌─────────────────────────────────────────────────────────────┐
│ 📊 DOCUMENTATION SITE STATUS                                │
├─────────────────────────────────────────────────────────────┤
│ Project: aiterm   Framework: MkDocs Material   Preset: data-wise │
│ 📁 CONTENT   Pages: 12 · Words: ~4,500 · Images: 3          │
│ 🔧 BUILD     ✅ Builds · ⚠️ 1 warning · Last build: 2h ago   │
│ 🔗 LINKS     ✅ Internal 45/45 · ✅ External 12/12           │
│ 📊 MERMAID   ✅ custom_fences · ✅ No CDN · ✅ CSS · ○ 15 diagrams │
│ 🚀 DEPLOY    GitHub Pages · <url> · Last: Dec 26 · ✅ Live   │
│ 📅 FRESHNESS Code: 3h ago · Docs: 2 days ago · ⚠️ May be stale │
│ QUICK ACTIONS [1] update [2] preview [3] deploy [4] check    │
└─────────────────────────────────────────────────────────────┘
```

## Health score model

```
SITE HEALTH: 90/100 █████████░
  Build: ✅ 20/20 · Links: ✅ 20/20 · Mermaid: ✅ 15/15
  Freshness: ⚠️ 15/20 (docs older than code) · Deployment: ✅ 20/25
```

**Mermaid health scoring:**

| Check | Points | Criteria |
|-------|--------|----------|
| custom_fences | 5 | Configured for diagrams to render |
| mermaid native | 5 | superfences custom_fences configured |
| Mermaid CSS | 5 | Overflow/styling CSS present |
| Missing any | −10 | Critical: diagrams show as code! |

## `--quick` mode

```
✅ aiterm docs | 12 pages | Build OK | Links OK | ⚠️ Stale (2 days) | Last deploy: Dec 26
```

## `--check` mode

Detailed validation report: BUILD VALIDATION · NAVIGATION CHECK · LINK VALIDATION (per-file) ·
CONTENT ANALYSIS · MERMAID DIAGRAMS (config + per-diagram syntax) · DESIGN CONSISTENCY · SUMMARY
(passed / warnings / errors) + a `/craft:site:update` recommendation.

## Status indicators

`✅` all good · `⚠️` warning, address soon · `❌` error, immediate · `○` info only.

## Freshness thresholds

| Gap | Status | Recommendation |
|-----|--------|----------------|
| < 1 day | ✅ Fresh | No action |
| 1–3 days | ⚠️ Getting stale | Update soon |
| > 3 days | ⚠️ Stale | Update recommended |
| > 1 week | ❌ Very stale | Update urgently |
