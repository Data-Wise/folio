#!/usr/bin/env bash
# scripts/bump-version.sh — folio version bump + count sync
#
# Adapter over scripts/lib/schema.sh (the single source of truth for every
# count, path, and doc-file list). This script never re-implements a
# find/grep count inline — it only orchestrates the schema.sh helpers.
#
# Usage:
#   ./scripts/bump-version.sh 1.0.0              # Full bump: version + counts + CHANGELOG
#   ./scripts/bump-version.sh 1.0.0 --dry-run    # Preview changes without writing
#   ./scripts/bump-version.sh --counts-only      # Recount actuals -> counts.json + doc files
#
# Modes:
#   version X.Y.Z   bump .claude-plugin/plugin.json version, stamp version
#                   patterns in the count-carrying doc files
#                   (FOLIO_COUNT_DOC_FILES), sync counts everywhere, and
#                   convert the CHANGELOG.md "## [Unreleased]" placeholder
#                   into "## [X.Y.Z] - YYYY-MM-DD" (a fresh [Unreleased]
#                   header is re-inserted above it).
#   --counts-only   recount live actuals (commands/agents/skills + per-
#                   category) and write them into scripts/config/counts.json
#                   AND the doc files. No version change, CHANGELOG untouched.
#
# Exclusions: scripts/config/exclusions.txt is honored — whole-file entries
# skip the file entirely; "file:N commands" entries preserve that exact
# historical phrase while the rest of the file is synced.
#
# Exit codes: 0 = success, 1 = environment/config error, 2 = usage error
#
# Portability: bash 3.2 (macOS) + Ubuntu CI. No jq (python3 via schema.sh
# guard); in-place sed goes through the BSD/GNU-portable sedi wrapper.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/lib/schema.sh"

# sedi — BSD/GNU portable in-place sed. The canonical flavor-detecting
# implementation lives in schema.sh (folio_sedi); this alias keeps call
# sites short and matches the craft convention.
sedi() { folio_sedi "$@"; }

# Colors (plain when stdout is not a tty)
if [ -t 1 ]; then
    RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; YELLOW=$'\033[1;33m'
    CYAN=$'\033[0;36m'; NC=$'\033[0m'
else
    RED=""; GREEN=""; YELLOW=""; CYAN=""; NC=""
fi

usage() {
    echo "Usage: $0 [VERSION] [--dry-run] [--counts-only]"
    echo ""
    echo "  VERSION        Target version (e.g. 1.0.0) — full bump mode"
    echo "  --dry-run, -n  Preview changes without writing"
    echo "  --counts-only  Sync counts only (counts.json + doc files, no version bump)"
    echo "  --help, -h     Show this help"
}

DRY_RUN=false
COUNTS_ONLY=false
NEW_VERSION=""

while [ $# -gt 0 ]; do
    case "$1" in
        --dry-run|-n)  DRY_RUN=true ;;
        --counts-only) COUNTS_ONLY=true ;;
        --help|-h)     usage; exit 0 ;;
        *)
            if [[ "$1" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                if [ -n "$NEW_VERSION" ]; then
                    echo "${RED}Error: multiple versions given ('$NEW_VERSION' and '$1')${NC}" >&2
                    exit 2
                fi
                NEW_VERSION="$1"
            else
                echo "${RED}Error: Unknown argument '$1'${NC}" >&2
                usage >&2
                exit 2
            fi
            ;;
    esac
    shift
done

if [ "$COUNTS_ONLY" = true ] && [ -n "$NEW_VERSION" ]; then
    echo "${RED}Error: Cannot specify a version with --counts-only${NC}" >&2; exit 2
fi
if [ "$COUNTS_ONLY" = false ] && [ -z "$NEW_VERSION" ]; then
    echo "${RED}Error: Version required (or use --counts-only)${NC}" >&2
    usage >&2
    exit 2
fi

folio_require_python3 || exit 1

cd "$FOLIO_ROOT"

# ---------------------------------------------------------------------------
# Current state
# ---------------------------------------------------------------------------
CURRENT_VERSION=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1])).get("version","unknown"))' "$FOLIO_PLUGIN_JSON" 2>/dev/null || echo "unknown")

if [ "$COUNTS_ONLY" = false ] && [ ! -f "$FOLIO_PLUGIN_JSON" ]; then
    echo "${RED}Error: $FOLIO_PLUGIN_JSON not found — cannot bump version${NC}" >&2
    exit 1
fi

if [ "$COUNTS_ONLY" = true ]; then
    TARGET_VERSION="$CURRENT_VERSION"
else
    TARGET_VERSION="$NEW_VERSION"
fi

# Live actual counts — ONLY via schema.sh helpers
CMD_COUNT=$(folio_actual_commands)
AGENT_COUNT=$(folio_actual_agents)
SKILL_COUNT=$(folio_actual_skills)

# Per-category actuals for the categories tracked in counts.json
# (word-splitting of the simple "name value name value ..." token list is
# intentional — category names are plain identifiers per schema.sh)
CAT_ARGS=""
for _cat in $FOLIO_CMD_CATEGORIES; do
    CAT_ARGS="$CAT_ARGS $_cat $(folio_actual_category_commands "$_cat")"
done

# ---------------------------------------------------------------------------
# Banner
# ---------------------------------------------------------------------------
if [ "$DRY_RUN" = true ]; then
    echo "${CYAN}bump-version.sh --dry-run${NC}"
else
    echo "${CYAN}bump-version.sh${NC}"
fi
echo "=============================="
if [ "$COUNTS_ONLY" = true ]; then
    echo "  Mode: ${YELLOW}counts-only${NC} (current version: v${CURRENT_VERSION})"
else
    echo "  Version: ${CURRENT_VERSION} -> ${GREEN}${TARGET_VERSION}${NC}"
fi
echo "  Counts:  ${CMD_COUNT} commands, ${AGENT_COUNT} agents, ${SKILL_COUNT} skills"
for _cat in $FOLIO_CMD_SCAN_CATEGORIES; do
    echo "           commands/${_cat}: $(folio_actual_category_commands "$_cat")"
done
echo ""

UPDATED=0

# ---------------------------------------------------------------------------
# counts.json — expected counts config (both modes)
# ---------------------------------------------------------------------------
update_counts_json() {
    local rel result
    rel="scripts/config/counts.json"

    if [ ! -f "$FOLIO_COUNTS_JSON" ]; then
        echo "  ${YELLOW}skip${NC} $rel (not found — see scripts/lib/schema.sh)"
        return 0
    fi
    if [ "$DRY_RUN" = true ]; then
        echo "  ${CYAN}would update${NC} $rel"
        return 0
    fi

    # $CAT_ARGS word-splits into "name value" pairs by design
    # shellcheck disable=SC2086
    result=$(python3 - "$FOLIO_COUNTS_JSON" "$CMD_COUNT" "$AGENT_COUNT" "$SKILL_COUNT" $CAT_ARGS <<'PYEOF'
import json, sys
path = sys.argv[1]
cmds, agents, skills = (int(v) for v in sys.argv[2:5])
pairs = sys.argv[5:]
try:
    data = json.load(open(path))
except Exception as e:
    sys.stderr.write("bump-version.sh: cannot read %s: %s\n" % (path, e))
    sys.exit(1)
before = json.dumps(data, sort_keys=True)
data["commands"], data["agents"], data["skills"] = cmds, agents, skills
cats = data.setdefault("categories", {})
it = iter(pairs)
for name in it:
    cats[name] = int(next(it))
if json.dumps(data, sort_keys=True) != before:
    with open(path, "w") as f:
        json.dump(data, f, indent=2)
        f.write("\n")
    print("updated")
else:
    print("unchanged")
PYEOF
)
    if [ "$result" = "updated" ]; then
        echo "  ${GREEN}+${NC} $rel"; UPDATED=$((UPDATED + 1))
    else
        echo "  ${YELLOW}-${NC} $rel (unchanged)"
    fi
}

# ---------------------------------------------------------------------------
# plugin.json — version key + count phrases inside the description string
# ---------------------------------------------------------------------------
# Count phrases ("N commands" etc.) are updated ONLY when already present in
# the description (folio_documented_plugin_count non-empty) — absent phrases
# stay absent, keeping the scaffold green until Phase 2 documents them.
update_plugin_json() {
    local rel="$1" mode key old new pj_args result
    if [ "$DRY_RUN" = true ]; then
        echo "  ${CYAN}would update${NC} $rel"
        return 0
    fi

    mode="counts"
    [ "$COUNTS_ONLY" = false ] && mode="version"

    pj_args=""
    for key in commands agents skills; do
        old=$(folio_documented_plugin_count "$key")
        [ -n "$old" ] || continue
        case "$key" in
            commands) new="$CMD_COUNT" ;;
            agents)   new="$AGENT_COUNT" ;;
            skills)   new="$SKILL_COUNT" ;;
        esac
        if folio_is_excluded "$rel" "$old $key"; then
            echo "    ${YELLOW}excluded${NC} $rel: '$old $key' preserved"
            continue
        fi
        pj_args="$pj_args $key=$new"
    done

    # $pj_args word-splits into key=value tokens by design
    # shellcheck disable=SC2086
    result=$(python3 - "$FOLIO_PLUGIN_JSON" "$mode" "$TARGET_VERSION" $pj_args <<'PYEOF'
import json, re, sys
path, mode, version = sys.argv[1], sys.argv[2], sys.argv[3]
data = json.load(open(path))
before = json.dumps(data, sort_keys=True)
if mode == "version":
    data["version"] = version
desc = data.get("description", "")
for pair in sys.argv[4:]:
    key, _, val = pair.partition("=")
    desc = re.sub(r"\d+(\s+)%s\b" % re.escape(key),
                  lambda m: "%s%s%s" % (val, m.group(1), key), desc)
if "description" in data:
    data["description"] = desc
if json.dumps(data, sort_keys=True) != before:
    with open(path, "w") as f:
        json.dump(data, f, indent=2)
        f.write("\n")
    print("updated")
else:
    print("unchanged")
PYEOF
)
    if [ "$result" = "updated" ]; then
        echo "  ${GREEN}+${NC} $rel"; UPDATED=$((UPDATED + 1))
    else
        echo "  ${YELLOW}-${NC} $rel (unchanged)"
    fi
}

# ---------------------------------------------------------------------------
# Markdown doc files — version stamps + count phrases
# ---------------------------------------------------------------------------
update_markdown_doc() {
    local f="$1" before after key new olds old
    if [ "$DRY_RUN" = true ]; then
        echo "  ${CYAN}would update${NC} $f"
        return 0
    fi

    before=$(cksum < "$f")

    # Version stamps (version mode only). Conservative, self-healing
    # patterns: badge slugs and explicit "Latest:/Current version:" labels —
    # never a blanket vX.Y.Z rewrite (historical prose mentions must survive).
    if [ "$COUNTS_ONLY" = false ]; then
        sedi "s|version-[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*|version-${TARGET_VERSION}|g" "$f"
        sedi "s|Latest: v[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*|Latest: v${TARGET_VERSION}|g" "$f"
        sedi "s|Current version: v[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*|Current version: v${TARGET_VERSION}|g" "$f"
        sedi "s|Current Version:\*\* v[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*|Current Version:** v${TARGET_VERSION}|g" "$f"
    fi

    # Count phrases (both modes). Collect the distinct stale values first,
    # then rewrite each exact phrase — guarded against digit-run bleed
    # ("3 commands" must not clobber the tail of "13 commands") and against
    # file:pattern exclusions (historical snapshots stay frozen).
    for key in commands agents skills; do
        case "$key" in
            commands) new="$CMD_COUNT" ;;
            agents)   new="$AGENT_COUNT" ;;
            skills)   new="$SKILL_COUNT" ;;
        esac
        olds=$(grep -o "[0-9][0-9]* ${key}" "$f" 2>/dev/null | awk '{print $1}' | sort -u)
        for old in $olds; do
            [ "$old" = "$new" ] && continue
            if folio_is_excluded "$f" "$old $key"; then
                echo "    ${YELLOW}excluded${NC} $f: '$old $key' preserved"
                continue
            fi
            sedi "s|\([^0-9]\)${old} ${key}|\1${new} ${key}|g" "$f"
            sedi "s|^${old} ${key}|${new} ${key}|" "$f"
        done
    done

    after=$(cksum < "$f")
    if [ "$before" != "$after" ]; then
        echo "  ${GREEN}+${NC} $f"; UPDATED=$((UPDATED + 1))
    else
        echo "  ${YELLOW}-${NC} $f (unchanged)"
    fi
}

# ---------------------------------------------------------------------------
# CHANGELOG.md — [Unreleased] placeholder handling (version mode only)
# ---------------------------------------------------------------------------
update_changelog() {
    local f="CHANGELOG.md" result
    [ "$COUNTS_ONLY" = true ] && return 0
    if [ ! -f "$f" ]; then
        echo "  ${YELLOW}skip${NC} $f (not found)"
        return 0
    fi
    if folio_is_excluded "$f"; then
        echo "  ${YELLOW}skip${NC} $f (excluded)"
        return 0
    fi
    if [ "$DRY_RUN" = true ]; then
        echo "  ${CYAN}would update${NC} $f"
        return 0
    fi

    result=$(python3 - "$f" "$TARGET_VERSION" "$(date +%Y-%m-%d)" <<'PYEOF'
import sys
path, version, today = sys.argv[1], sys.argv[2], sys.argv[3]
text = open(path).read()
if "## [%s]" % version in text:
    print("already-released")
    sys.exit(0)
placeholder = "## [Unreleased]"
if placeholder not in text:
    print("no-placeholder")
    sys.exit(0)
new = text.replace(placeholder,
                   "%s\n\n## [%s] - %s" % (placeholder, version, today), 1)
with open(path, "w") as f:
    f.write(new)
print("updated")
PYEOF
)
    case "$result" in
        updated)
            echo "  ${GREEN}+${NC} $f ([Unreleased] -> [${TARGET_VERSION}] - $(date +%Y-%m-%d))"
            UPDATED=$((UPDATED + 1))
            ;;
        already-released)
            echo "  ${YELLOW}-${NC} $f (v${TARGET_VERSION} section already present)"
            ;;
        no-placeholder)
            echo "  ${YELLOW}!${NC} $f: no '## [Unreleased]' placeholder found — add the section manually"
            ;;
    esac
}

# ---------------------------------------------------------------------------
# Run
# ---------------------------------------------------------------------------
echo "${CYAN}Counts config:${NC}"
update_counts_json
echo ""

echo "${CYAN}Doc files:${NC}"
DOC_FILES=$(folio_count_doc_files_existing)
if [ -z "$DOC_FILES" ]; then
    echo "  ${YELLOW}none${NC} of FOLIO_COUNT_DOC_FILES exist yet"
fi
for f in $DOC_FILES; do
    if folio_is_excluded "$f"; then
        echo "  ${YELLOW}skip${NC} $f (excluded)"
        continue
    fi
    case "$f" in
        *.json) update_plugin_json "$f" ;;
        *)      update_markdown_doc "$f" ;;
    esac
done
echo ""

if [ "$COUNTS_ONLY" = false ]; then
    echo "${CYAN}Changelog:${NC}"
    update_changelog
    echo ""
fi

if [ "$DRY_RUN" = true ]; then
    echo "${YELLOW}DRY RUN — no files were modified${NC}"
    echo "  Run without --dry-run to apply changes"
else
    echo "${GREEN}Done!${NC} Updated $UPDATED file(s)"
    [ "$COUNTS_ONLY" = false ] && echo "  Version: v${TARGET_VERSION}"
    echo "  Counts:  ${CMD_COUNT} commands, ${AGENT_COUNT} agents, ${SKILL_COUNT} skills"
fi
