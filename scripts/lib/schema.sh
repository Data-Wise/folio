#!/usr/bin/env bash
# scripts/lib/schema.sh — folio count-schema library (SINGLE SOURCE OF TRUTH)
#
# The ONE place that defines:
#   1. The category schema (command categories, agent/skill layout rules)
#   2. The doc files that carry live counts
#   3. Shell helpers to read expected counts (scripts/config/counts.json),
#      actual counts (filesystem), and documented counts (plugin.json)
#
# All adapter scripts (validate-counts.sh, bump-version.sh, docs-staleness
# check, pre-release check) MUST source this file and use ONLY the helpers
# below — never re-implement a find/grep count inline.
#
#   Usage:
#     SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
#     . "$SCRIPT_DIR/lib/schema.sh"      # from scripts/*.sh adapters
#
# Portability: bash 3.2 (macOS) + POSIX (ubuntu CI). No jq — JSON parsing
# goes through python3 (folio_require_python3 guards it). No associative
# arrays, no mapfile, no GNU-only flags. In-place sed via folio_sedi.
#
# ---------------------------------------------------------------------------
# CONTRACT (function/variable names the adapters rely on — do not rename)
# ---------------------------------------------------------------------------
# Variables:
#   FOLIO_ROOT                 absolute path to the plugin repo root
#   FOLIO_COUNTS_JSON          scripts/config/counts.json (expected counts)
#   FOLIO_EXCLUSIONS_FILE      scripts/config/exclusions.txt
#   FOLIO_PLUGIN_JSON          .claude-plugin/plugin.json
#   FOLIO_CMD_CATEGORIES       command categories tracked in counts.json
#                              (space-separated; currently: "docs")
#   FOLIO_CMD_SCAN_CATEGORIES  categories to scan/report, including the
#                              virtual "root" bucket (commands/*.md at depth
#                              1 — hub/do land there later). Currently:
#                              "docs root". "root" is scan-only until Phase 2
#                              adds it to counts.json categories.
#   FOLIO_COUNT_DOC_FILES      repo-relative doc files that carry live counts
#                              (space-separated). Currently:
#                              "README.md docs/index.md .claude-plugin/plugin.json"
#                              (plugin.json carries counts in its description
#                              string — see folio_documented_plugin_count).
#
# Functions (all echo a bare integer on stdout unless noted):
#   folio_sedi ARGS...                 portable in-place sed (BSD/GNU)
#   folio_require_python3              exit-code guard; 1 + stderr if absent
#   folio_expected_count KEY           expected count from counts.json;
#                                      KEY in commands|agents|skills.
#                                      Missing/invalid key: empty stdout,
#                                      stderr message, return 1.
#   folio_expected_commands            = folio_expected_count commands
#   folio_expected_agents              = folio_expected_count agents
#   folio_expected_skills              = folio_expected_count skills
#   folio_expected_category NAME       expected per-category command count
#                                      from counts.json .categories.NAME;
#                                      untracked NAME: empty, stderr, return 1.
#   folio_actual_commands              live count: commands/**/*.md minus
#                                      index.md/README.md
#   folio_actual_agents                live count: agents/**/*.md
#   folio_actual_skills                live count: skills/**/SKILL.md ONLY
#                                      (references/ trees excluded)
#   folio_actual_category_commands N   live per-category command count;
#                                      N is a dir under commands/, or "root"
#                                      for depth-1 commands/*.md
#   folio_documented_plugin_count KEY  count parsed from plugin.json
#                                      description ("N commands" etc.).
#                                      Empty stdout (return 0) when the
#                                      description carries no such phrase or
#                                      plugin.json is absent — adapters MUST
#                                      treat empty as "not documented, skip
#                                      comparison" (keeps checks green while
#                                      the surface is being built).
#   folio_count_doc_files_existing     print each FOLIO_COUNT_DOC_FILES entry
#                                      that exists on disk, one per line
#   folio_exclusions                   print effective exclusions.txt entries
#                                      (comments/blank lines stripped), one
#                                      per line; silent if file absent
#   folio_is_excluded FILE [PATTERN]   return 0 if repo-relative FILE (or
#                                      FILE with the exact count-phrase
#                                      PATTERN, e.g. "12 commands") is
#                                      excluded; matches whole-file lines,
#                                      "dir/" prefixes, and "file:pattern"
#                                      lines per exclusions.txt format
# ---------------------------------------------------------------------------

# Source guard — prevent double-loading
[ -n "${_FOLIO_SCHEMA_LOADED:-}" ] && return 0
_FOLIO_SCHEMA_LOADED=1

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
_FOLIO_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FOLIO_ROOT="$(cd "$_FOLIO_LIB_DIR/../.." && pwd)"
FOLIO_COUNTS_JSON="$FOLIO_ROOT/scripts/config/counts.json"
FOLIO_EXCLUSIONS_FILE="$FOLIO_ROOT/scripts/config/exclusions.txt"
FOLIO_PLUGIN_JSON="$FOLIO_ROOT/.claude-plugin/plugin.json"

# ---------------------------------------------------------------------------
# Category schema
# ---------------------------------------------------------------------------
# Command categories tracked in counts.json (.categories.<name>).
FOLIO_CMD_CATEGORIES="docs"
# Categories to scan/report: tracked ones + the virtual "root" bucket
# (commands/*.md at depth 1; /folio:hub and /folio:do land there later).
FOLIO_CMD_SCAN_CATEGORIES="docs root"

# Doc files that carry live counts (repo-relative). Keep this list SHORT and
# real — every entry here is swept by bump-version and policed by
# validate-counts. plugin.json carries counts inside its description string.
FOLIO_COUNT_DOC_FILES="README.md docs/index.md .claude-plugin/plugin.json"

# ---------------------------------------------------------------------------
# Portable in-place sed (BSD sed on macOS needs -i ''; GNU sed rejects it)
# ---------------------------------------------------------------------------
if sed --version >/dev/null 2>&1; then
    folio_sedi() { sed -i "$@"; }      # GNU
else
    folio_sedi() { sed -i '' "$@"; }   # BSD / macOS
fi

# ---------------------------------------------------------------------------
# python3 guard (JSON parsing dependency — no jq)
# ---------------------------------------------------------------------------
folio_require_python3() {
    if ! command -v python3 >/dev/null 2>&1; then
        echo "schema.sh: python3 is required (JSON parsing) but not found" >&2
        return 1
    fi
    return 0
}

# ---------------------------------------------------------------------------
# Expected counts — from scripts/config/counts.json (single source of truth)
# ---------------------------------------------------------------------------
# folio_expected_count KEY  (KEY: commands | agents | skills)
# Echoes the integer. On missing file/key or non-integer value: empty stdout,
# message on stderr, return 1 — adapters should fail loudly, not guess.
folio_expected_count() {
    folio_require_python3 || return 1
    python3 - "$FOLIO_COUNTS_JSON" "$1" <<'PYEOF'
import json, sys
path, key = sys.argv[1], sys.argv[2]
try:
    data = json.load(open(path))
except Exception as e:
    sys.stderr.write("schema.sh: cannot read %s: %s\n" % (path, e))
    sys.exit(1)
val = data.get(key)
if not isinstance(val, int) or isinstance(val, bool):
    sys.stderr.write("schema.sh: key '%s' missing or non-integer in counts.json\n" % key)
    sys.exit(1)
print(val)
PYEOF
}

folio_expected_commands() { folio_expected_count commands; }
folio_expected_agents()   { folio_expected_count agents; }
folio_expected_skills()   { folio_expected_count skills; }

# folio_expected_category NAME — expected command count for a tracked
# category (counts.json .categories.NAME). Untracked NAME (e.g. "root"
# today): empty stdout, stderr note, return 1.
folio_expected_category() {
    folio_require_python3 || return 1
    python3 - "$FOLIO_COUNTS_JSON" "$1" <<'PYEOF'
import json, sys
path, cat = sys.argv[1], sys.argv[2]
try:
    cats = json.load(open(path)).get("categories", {})
except Exception as e:
    sys.stderr.write("schema.sh: cannot read %s: %s\n" % (path, e))
    sys.exit(1)
val = cats.get(cat)
if not isinstance(val, int) or isinstance(val, bool):
    sys.stderr.write("schema.sh: category '%s' not tracked in counts.json\n" % cat)
    sys.exit(1)
print(val)
PYEOF
}

# ---------------------------------------------------------------------------
# Actual counts — from the filesystem
# ---------------------------------------------------------------------------
# All counters tolerate missing directories (empty surface counts as 0), so
# the validators run green on the current 0/0/0 tree.

# Commands: every .md under commands/ except index.md / README.md.
folio_actual_commands() {
    find "$FOLIO_ROOT/commands" -name "*.md" \
        ! -name "index.md" ! -name "README.md" 2>/dev/null | wc -l | tr -d ' '
}

# Agents: every .md under agents/ (including agents/docs/).
folio_actual_agents() {
    find "$FOLIO_ROOT/agents" -name "*.md" 2>/dev/null | wc -l | tr -d ' '
}

# Skills: SKILL.md files ONLY (skills/**/SKILL.md). Supporting material in
# references/ trees never counts — enforced by both the -name filter and the
# explicit -path guard.
folio_actual_skills() {
    find "$FOLIO_ROOT/skills" -name "SKILL.md" \
        ! -path "*/references/*" 2>/dev/null | wc -l | tr -d ' '
}

# folio_actual_category_commands NAME — per-category live command count.
# NAME "root" = depth-1 commands/*.md (hub/do); anything else = commands/NAME/.
folio_actual_category_commands() {
    case "$1" in
        root)
            find "$FOLIO_ROOT/commands" -maxdepth 1 -name "*.md" \
                ! -name "index.md" ! -name "README.md" 2>/dev/null | wc -l | tr -d ' '
            ;;
        *)
            find "$FOLIO_ROOT/commands/$1" -name "*.md" \
                ! -name "index.md" ! -name "README.md" 2>/dev/null | wc -l | tr -d ' '
            ;;
    esac
}

# ---------------------------------------------------------------------------
# Documented counts — parsed from plugin.json description
# ---------------------------------------------------------------------------
# folio_documented_plugin_count KEY  (KEY: commands | agents | skills)
# Parses "N commands" / "N agents" / "N skills" out of the description
# string. Prints the number when present. Prints NOTHING (return 0) when the
# phrase or plugin.json is absent — adapters treat empty output as "not
# documented yet, skip the comparison", which keeps validation green while
# the plugin surface is still being scaffolded.
folio_documented_plugin_count() {
    folio_require_python3 || return 1
    python3 - "$FOLIO_PLUGIN_JSON" "$1" <<'PYEOF'
import json, re, sys
path, key = sys.argv[1], sys.argv[2]
try:
    desc = json.load(open(path)).get("description", "")
except Exception:
    sys.exit(0)   # no plugin.json yet -> "not documented"
m = re.search(r"(\d+)\s+%s\b" % re.escape(key), desc)
if m:
    print(m.group(1))
PYEOF
}

# ---------------------------------------------------------------------------
# Count-carrying doc files
# ---------------------------------------------------------------------------
# Print each FOLIO_COUNT_DOC_FILES entry that exists on disk, one per line
# (repo-relative). Adapters iterate this instead of hardcoding file lists.
folio_count_doc_files_existing() {
    local f
    for f in $FOLIO_COUNT_DOC_FILES; do
        [ -f "$FOLIO_ROOT/$f" ] && echo "$f"
    done
    return 0
}

# ---------------------------------------------------------------------------
# Exclusions — scripts/config/exclusions.txt (craft-compatible format)
# ---------------------------------------------------------------------------
# folio_exclusions — print effective entries (comments/blanks stripped),
# one per line. Silent no-op if the file is absent.
folio_exclusions() {
    [ -f "$FOLIO_EXCLUSIONS_FILE" ] || return 0
    # Strip leading whitespace, then drop comments and blank lines.
    sed 's/^[[:space:]]*//' "$FOLIO_EXCLUSIONS_FILE" | grep -v '^#' | grep -v '^$'
    return 0
}

# folio_is_excluded FILE [PATTERN]
#   FILE    repo-relative path (e.g. "docs/CHANGELOG.md")
#   PATTERN optional exact count-phrase (e.g. "12 commands") for
#           file:pattern entries
# Return 0 (excluded) when any entry matches:
#   dir/          — FILE is under that directory
#   file          — whole-file exclusion
#   file:pattern  — FILE matches and PATTERN equals the entry's pattern
# Return 1 otherwise.
folio_is_excluded() {
    local target="$1" pattern="${2:-}"
    local line entry_file entry_pat
    [ -f "$FOLIO_EXCLUSIONS_FILE" ] || return 1
    while IFS= read -r line; do
        case "$line" in
            */)
                # Directory exclusion (prefix match)
                case "$target" in
                    "$line"*) return 0 ;;
                esac
                ;;
            *:*)
                # file:pattern exclusion (exact pattern match)
                entry_file="${line%%:*}"
                entry_pat="${line#*:}"
                if [ "$entry_file" = "$target" ] && [ -n "$pattern" ] \
                    && [ "$entry_pat" = "$pattern" ]; then
                    return 0
                fi
                ;;
            *)
                # Whole-file exclusion
                [ "$line" = "$target" ] && return 0
                ;;
        esac
    done <<EOF_EXCL
$(folio_exclusions)
EOF_EXCL
    return 1
}
