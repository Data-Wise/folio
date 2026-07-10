#!/usr/bin/env bash
# scripts/post-release-sweep.sh - Post-release version-drift sweep (folio)
#
# Folio-minimal adaptation of craft's post-release-sweep.sh: after a release,
# verify that no count-carrying doc file (schema.sh's FOLIO_COUNT_DOC_FILES
# list) still carries the OLD version string. Reports drift; --fix applies
# mechanical corrections via folio_sedi.
#
# All schema knowledge (doc-file list, exclusions, portable sed) comes from
# scripts/lib/schema.sh — nothing is hardcoded here.
#
# Usage:
#   ./scripts/post-release-sweep.sh                    # Dry-run (default)
#   ./scripts/post-release-sweep.sh --fix              # Auto-fix stale refs
#   ./scripts/post-release-sweep.sh --version 1.0.0    # Check against specific version
#   ./scripts/post-release-sweep.sh --prev 0.9.0       # Explicit previous version
#   ./scripts/post-release-sweep.sh --dry-run          # Explicit dry-run
#
# Exit codes: 0 = clean (or nothing to sweep yet), 1 = drift found, 2 = usage/setup error
#
# Portability: bash 3.2 (macOS) + POSIX (ubuntu CI). No `head -n -N`, no
# mapfile, no associative arrays. In-place sed via schema.sh's folio_sedi.

# No `set -e` — explicit exit-code checks control the flow (same rationale
# as craft's sweep).
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ ! -f "$SCRIPT_DIR/lib/schema.sh" ]]; then
    echo "Error: $SCRIPT_DIR/lib/schema.sh not found — schema library is required" >&2
    exit 2
fi
. "$SCRIPT_DIR/lib/schema.sh"

# Colors (only when stdout is a terminal)
if [[ -t 1 ]]; then
    RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; YELLOW=$'\033[1;33m'
    CYAN=$'\033[0;36m'; NC=$'\033[0m'
else
    RED=""; GREEN=""; YELLOW=""; CYAN=""; NC=""
fi

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
FIX_MODE=false
TARGET_VERSION=""
PREV_OVERRIDE=""

usage() {
    echo "Usage: $0 [--fix] [--dry-run] [--version X.Y.Z] [--prev X.Y.Z]"
    echo ""
    echo "  --fix          Auto-fix stale version refs (via portable sed)"
    echo "  --dry-run, -n  Report only, no changes (default)"
    echo "  --version      Current version to check against (default: from plugin.json)"
    echo "  --prev         Previous version to sweep for (default: derived by decrement)"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --fix)        FIX_MODE=true ;;
        --dry-run|-n) FIX_MODE=false ;;
        --version)
            if [[ $# -lt 2 ]] || [[ ! "$2" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                echo "${RED}Error: --version requires a version argument (X.Y.Z)${NC}" >&2
                exit 2
            fi
            TARGET_VERSION="$2"
            shift
            ;;
        --prev)
            if [[ $# -lt 2 ]] || [[ ! "$2" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                echo "${RED}Error: --prev requires a version argument (X.Y.Z)${NC}" >&2
                exit 2
            fi
            PREV_OVERRIDE="$2"
            shift
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            echo "${RED}Error: Unknown argument '$1'${NC}" >&2
            usage >&2
            exit 2
            ;;
    esac
    shift
done

cd "$FOLIO_ROOT"

# ---------------------------------------------------------------------------
# Resolve current version (plugin.json unless --version given)
# ---------------------------------------------------------------------------
CHECK_VERSION="$TARGET_VERSION"
if [[ -z "$CHECK_VERSION" ]]; then
    if [[ ! -f "$FOLIO_PLUGIN_JSON" ]]; then
        # Scaffold-green semantics: no plugin.json yet means there has been no
        # release to sweep after. Report and exit clean (same skip contract as
        # folio_documented_plugin_count's empty result).
        echo "${CYAN}Post-Release Sweep${NC} — no .claude-plugin/plugin.json yet; nothing to sweep (skip)"
        exit 0
    fi
    folio_require_python3 || exit 2
    CHECK_VERSION=$(python3 -c "import json,sys; print(json.load(open(sys.argv[1])).get('version',''))" \
        "$FOLIO_PLUGIN_JSON" 2>/dev/null || true)
    if [[ ! "$CHECK_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "${RED}Error: cannot determine version from plugin.json (got '${CHECK_VERSION}'); use --version X.Y.Z${NC}" >&2
        exit 2
    fi
fi

# ---------------------------------------------------------------------------
# Derive previous version (decrement patch, else minor) unless --prev given
# ---------------------------------------------------------------------------
PREV_VERSION="$PREV_OVERRIDE"
if [[ -z "$PREV_VERSION" ]]; then
    MAJOR=$(echo "$CHECK_VERSION" | cut -d. -f1)
    MINOR=$(echo "$CHECK_VERSION" | cut -d. -f2)
    PATCH=$(echo "$CHECK_VERSION" | cut -d. -f3)
    if [[ "$PATCH" -gt 0 ]]; then
        PREV_VERSION="${MAJOR}.${MINOR}.$((PATCH - 1))"
    elif [[ "$MINOR" -gt 0 ]]; then
        PREV_VERSION="${MAJOR}.$((MINOR - 1)).0"
    else
        PREV_VERSION=""
    fi
fi

echo "${CYAN}Post-Release Sweep${NC} (v${CHECK_VERSION})"
echo "=============================="
if [[ "$FIX_MODE" == true ]]; then
    echo "  Mode: ${YELLOW}fix${NC}"
else
    echo "  Mode: ${CYAN}dry-run${NC}"
fi

if [[ -z "$PREV_VERSION" ]]; then
    echo ""
    echo "  ${YELLOW}SKIP${NC} — cannot derive previous version (patch=0, minor=0); use --prev X.Y.Z"
    exit 0
fi

echo "  Sweeping for stale refs to: v${PREV_VERSION}"
echo ""

# Regex-safe previous version (escape the dots)
PREV_RE=$(echo "$PREV_VERSION" | sed 's/\./\\./g')

# ---------------------------------------------------------------------------
# Sweep the schema-defined doc list for old version strings
# ---------------------------------------------------------------------------
DRIFT_COUNT=0
FIXED_COUNT=0
SWEPT_FILES=0
SKIPPED_FILES=0

# Iterate schema.sh's count-carrying doc list (never hardcode the file set).
# Process substitution is avoided for POSIX friendliness; a heredoc keeps the
# loop in the current shell so the counters survive.
DOC_FILES=$(folio_count_doc_files_existing)

while IFS= read -r file; do
    [[ -z "$file" ]] && continue

    # Whole-file / directory exclusions from scripts/config/exclusions.txt
    if folio_is_excluded "$file"; then
        SKIPPED_FILES=$((SKIPPED_FILES + 1))
        echo "  ${CYAN}SKIP${NC}  $file (excluded via exclusions.txt)"
        continue
    fi
    # Pattern-level exclusion: a "file:vX.Y.Z" entry sanctions that old
    # version string in that file (e.g. a historical snapshot line).
    if folio_is_excluded "$file" "v${PREV_VERSION}"; then
        SKIPPED_FILES=$((SKIPPED_FILES + 1))
        echo "  ${CYAN}SKIP${NC}  $file (v${PREV_VERSION} sanctioned via exclusions.txt)"
        continue
    fi

    SWEPT_FILES=$((SWEPT_FILES + 1))

    # Same stale-ref shapes craft sweeps: vX.Y.Z, "X.Y.Z", standalone X.Y.Z,
    # and badge-style version-X.Y.Z. Separate -e patterns (not \| alternation):
    # BSD grep treats a mid-pattern $ before \| as a literal, silently
    # disabling the end-of-line anchor on macOS.
    STALE_LINES=$(grep -n \
        -e "v${PREV_RE}\b" \
        -e "\"${PREV_RE}\"" \
        -e " ${PREV_RE} " \
        -e "${PREV_RE}\$" \
        -e "version-${PREV_RE}" \
        "$file" 2>/dev/null || true)

    if [[ -n "$STALE_LINES" ]]; then
        STALE_COUNT=$(printf '%s\n' "$STALE_LINES" | wc -l | tr -d ' ')
        DRIFT_COUNT=$((DRIFT_COUNT + STALE_COUNT))

        if [[ "$FIX_MODE" == true ]]; then
            # One sedi rule per detected shape (LHS uses the dot-escaped
            # regex so "1x0y0" can never false-match). The end-of-line rule
            # requires a preceding non-version character so "21.0.0" at EOL
            # is left for manual review rather than half-rewritten.
            folio_sedi "s|v${PREV_RE}|v${CHECK_VERSION}|g" "$file"
            folio_sedi "s|version-${PREV_RE}|version-${CHECK_VERSION}|g" "$file"
            folio_sedi "s|\"${PREV_RE}\"|\"${CHECK_VERSION}\"|g" "$file"
            folio_sedi "s| ${PREV_RE} | ${CHECK_VERSION} |g" "$file"
            folio_sedi "s|\([^0-9.]\)${PREV_RE}\$|\1${CHECK_VERSION}|" "$file"
            FIXED_COUNT=$((FIXED_COUNT + STALE_COUNT))
            echo "  ${GREEN}FIXED${NC} $file (${STALE_COUNT} stale v${PREV_VERSION} ref(s))"
        else
            echo "  ${YELLOW}STALE${NC} $file (${STALE_COUNT} ref(s) to v${PREV_VERSION})"
            # Show up to 3 offending lines for context
            printf '%s\n' "$STALE_LINES" | head -3 | while IFS= read -r line; do
                echo "    ${line}"
            done
        fi
    fi
done <<EOF_DOCS
$DOC_FILES
EOF_DOCS

if [[ $SWEPT_FILES -eq 0 ]] && [[ $SKIPPED_FILES -eq 0 ]]; then
    echo "  ${CYAN}SKIP${NC}  no count-carrying doc files exist yet (empty surface)"
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
echo "=============================="
if [[ $DRIFT_COUNT -eq 0 ]]; then
    echo "${GREEN}ALL CLEAN${NC} — no stale v${PREV_VERSION} refs in ${SWEPT_FILES} doc file(s)"
    exit 0
fi

if [[ "$FIX_MODE" == true ]]; then
    echo "${GREEN}Auto-fixed ${FIXED_COUNT} stale ref(s).${NC} Re-run to confirm clean."
else
    echo "${YELLOW}Drift:${NC} ${DRIFT_COUNT} stale v${PREV_VERSION} ref(s) found"
    echo "Run with ${CYAN}--fix${NC} to auto-correct them."
fi
exit 1
