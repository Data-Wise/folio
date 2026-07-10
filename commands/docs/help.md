---
description: "/folio:docs:help - Help Page Generator"
category: docs
---

# /folio:docs:help - Help Page Generator

> Also reachable via `/folio:docs:generate help` (unified router across all 9 doc generators).

Generate comprehensive help documentation for commands using ADHD-friendly templates.

## Purpose

**One command to document any command:**

- Extracts info from command file and --help output
- Uses `HELP-PAGE-TEMPLATE.md` for consistent structure
- Generates examples, options tables, and troubleshooting
- Links to related commands and workflows

## Usage

```bash
# Generate help for a specific command
/folio:docs:help "check"              # Document /craft:check
/folio:docs:help "docs:update"        # Document /craft:docs:update
/folio:docs:help "git:worktree"       # Document /craft:git:worktree

# Generate help for multiple commands
/folio:docs:help "docs:*"             # All docs commands
/folio:docs:help "git:*"              # All git commands

# Options
/folio:docs:help "check" --output docs/help/   # Custom output path
/folio:docs:help "check" --format terminal     # Preview in terminal
/folio:docs:help "check" --dry-run             # Show plan only
```

## When Invoked

### Step 1: Locate Command

```bash
# Find command file
find commands/ -name "*.md" | grep -i "[command-name]"

# Read command definition
cat commands/[category]/[command].md
```

```
┌─────────────────────────────────────────────────────────────┐
│ Step 1/4: LOCATING COMMAND                                  │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│ Command: /craft:docs:update                                 │
│ File: commands/docs/update.md                               │
│ Category: docs                                              │
│                                                             │
│ Found:                                                      │
│   • 15 flags                                                │
│   • 6 usage examples                                        │
│   • 5 integration points                                    │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Step 2: Extract Information

Extract from command file:

- Synopsis (usage pattern)
- Description (purpose)
- Flags and arguments
- Examples
- Integration with other commands

```
┌─────────────────────────────────────────────────────────────┐
│ Step 2/4: EXTRACTING INFO                                   │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│ Synopsis: /craft:docs:update [feature] [flags]              │
│                                                             │
│ Arguments:                                                  │
│   • [feature] - Optional feature name to scope              │
│                                                             │
│ Flags:                                                      │
│   • --force         Full cycle regardless of detection      │
│   • --dry-run       Preview plan without executing          │
│   • --with-tutorial Force tutorial generation               │
│   • --with-help     Force help page generation              │
│   • --threshold N   Override scoring threshold              │
│   • (10 more...)                                            │
│                                                             │
│ Examples: 6 found                                           │
│ Related: 8 commands                                         │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Step 3: Generate Help Page

Load template and fill sections:

```
┌─────────────────────────────────────────────────────────────┐
│ Step 3/4: GENERATING HELP PAGE                              │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│ Template: templates/docs/HELP-PAGE-TEMPLATE.md              │
│                                                             │
│ Sections generated:                                         │
│   ✓ Synopsis (with 3 quick examples)                        │
│   ✓ Description (purpose + use cases)                       │
│   ✓ Options (15 flags in tables)                            │
│   ✓ Examples (6 detailed examples)                          │
│   ✓ Integration (8 related commands)                        │
│   ✓ Troubleshooting (common issues)                         │
│   ✓ See Also (links to tutorials, workflows)                │
│                                                             │
│ Output: docs/help/docs-update.md (245 lines)                │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Step 4: Validate & Link

```
┌─────────────────────────────────────────────────────────────┐
│ Step 4/4: VALIDATING                                        │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│ ✓ All internal links valid                                  │
│ ✓ Examples syntax checked                                   │
│ ✓ Added to mkdocs.yml navigation                            │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Output Structure

Generated help page follows this structure:

````markdown
# /craft:docs:update

> **Smart documentation generator - detect changes and generate all needed docs.**

---

## Synopsis

```bash
/craft:docs:update [feature] [flags]
```

**Quick examples:**

```bash
/craft:docs:update                    # Auto-detect and generate
/craft:docs:update "auth"             # Document auth feature
/craft:docs:update --with-tutorial    # Force tutorial
```

---

## Description

[Extracted from command file]

---

## Options

| Flag | Effect |
|------|--------|
| `--force` | Full cycle regardless of detection |
| ... | ... |

---

## Examples

### Basic Usage

[Example 1]

### Feature-Specific

[Example 2]

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Docs not generating | Lower threshold with --threshold 2 |
| ... | ... |

---

## See Also

- [Tutorial: Documentation Workflow](../tutorials/docs-workflow.md)
- [Workflow: Feature Documentation](../workflows/feature-docs.md)
- Related: /craft:docs:sync, /craft:docs:guide, /craft:docs:check

````

## Flags Reference

| Flag | Effect |
|------|--------|
| (none) | Generate help page to docs/help/ |
| `--output PATH` | Custom output directory |
| `--format terminal` | Preview in terminal only |
| `--format json` | Output as JSON |
| `--dry-run` | Show plan without generating |
| `--verbose` | Detailed output |
| `--no-nav` | Skip mkdocs.yml update |

## Integration

**Uses template:** `templates/docs/HELP-PAGE-TEMPLATE.md`

**Called by:**

- `/craft:docs:update --with-help`
- `/craft:docs:update` (when score >= 2 for help type)

**Outputs to:**

- `docs/help/[command-name].md` (default)
- Custom path with `--output`

## ADHD-Friendly Design

1. **Consistent structure** - Same format for every command
2. **Examples first** - Quick examples right after synopsis
3. **Tables for scanning** - Options and troubleshooting in tables
4. **Cross-references** - Links to related content
5. **One command** - No manual template filling

## See Also

- `/folio:docs:api` - OpenAPI/Swagger documentation generator
- `/craft:docs:changelog` - Auto-update CHANGELOG.md based on git commits
- `/folio:docs:demo` - Terminal recording and GIF generator with dependency management
- `/folio:docs:lint` - Markdown quality and error detection with auto-fix
- `/craft:docs:nav-update` - Update mkdocs.yml navigation from directory structure
- `/folio:docs:prompt` - Generate documentation prompts
- `/folio:docs:quickstart` - Quick start generator
- `/folio:docs:site` - Website documentation focus
- `/folio:docs:tutorial` - Interactive tutorial generator
- `/folio:docs:website` - ADHD-friendly website enhancement
- `/folio:docs:workflow` - Workflow documentation generator
