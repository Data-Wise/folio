#!/bin/bash
# pre-release-check.sh - Validate folio release consistency before tagging
#
# Adapted from craft's scripts/pre-release-check.sh (folio-minimal gates).
#
# Usage:
#   ./scripts/pre-release-check.sh <version>       # e.g. 1.0.0 (or v1.0.0)
#
# Expects the version ALREADY bumped in the tree (craft convention):
# run bump/version edits first, then this check, then tag.
#
# Gates:
#   1. plugin.json version matches target (plugin.json is the only
#      version-carrying package file for now)
#   2. validate-counts.sh green (skipped with a warning while the
#      scaffold has not placed it yet)
#   3. mkdocs build --strict IF mkdocs.yml exists (clean skip if absent)
#   4. Working tree clean (no uncommitted or untracked changes)
#   5. CHANGELOG.md has a section for the target version
#
# Exit codes: 0 = ready to release, 1 = one or more gates failed.
#
# bash 3.2 / POSIX-safe: no 'head -n -N', no bash-4 features. In-place
# sed (if ever needed) must go through folio_sedi from lib/schema.sh.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FOLIO_ROOT="$(dirname "$SCRIPT_DIR")"

# --------------------------------------------------------------------------
# Shared schema library (single source of truth for paths/counters).
# Tolerate absence during scaffold: fall back to local path definitions.
# --------------------------------------------------------------------------
if [ -f "$SCRIPT_DIR/lib/schema.sh" ]; then
    # shellcheck source=lib/schema.sh
    . "$SCRIPT_DIR/lib/schema.sh"
fi
: "${FOLIO_PLUGIN_JSON:=$FOLIO_ROOT/.claude-plugin/plugin.json}"

# Colors (inline; folio has no formatting.sh). Disabled when stdout is not
# a tty or NO_COLOR is set.
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    CYAN='\033[0;36m'
    NC='\033[0m'
else
    RED='' GREEN='' YELLOW='' CYAN='' NC=''
fi

say() { printf '%b\n' "$1"; }

cd "$FOLIO_ROOT"

# --------------------------------------------------------------------------
# Target version (required; leading "v" tolerated)
# --------------------------------------------------------------------------
if [ -z "${1:-}" ]; then
    say "${RED}Error: version argument required${NC}"
    echo "Usage: $0 <version>   (e.g. $0 1.0.0)"
    exit 1
fi
TARGET_VERSION="${1#v}"

case "$TARGET_VERSION" in
    [0-9]*.[0-9]*.[0-9]*) : ;;
    *)
        say "${RED}Error: '$TARGET_VERSION' does not look like a semver version (X.Y.Z)${NC}"
        exit 1
        ;;
esac

say "${CYAN}folio Pre-Release Validation for v${TARGET_VERSION}${NC}"
echo "==========================================="
echo ""

ERRORS=0

# python3 is required for JSON parsing (no jq dependency)
if command -v python3 >/dev/null 2>&1; then
    HAVE_PY3=1
else
    HAVE_PY3=0
fi

# --------------------------------------------------------------------------
# Gate 1: plugin.json version matches target
# --------------------------------------------------------------------------
say "${CYAN}[1/5] Plugin version consistency${NC}"

if [ ! -f "$FOLIO_PLUGIN_JSON" ]; then
    say "${RED}  x plugin.json not found at $FOLIO_PLUGIN_JSON${NC}"
    ERRORS=$((ERRORS + 1))
elif [ "$HAVE_PY3" -eq 0 ]; then
    say "${RED}  x python3 not found — cannot parse plugin.json${NC}"
    ERRORS=$((ERRORS + 1))
else
    PLUGIN_VERSION="$(python3 -c "import json; print(json.load(open('$FOLIO_PLUGIN_JSON'))['version'])" 2>/dev/null || true)"
    if [ -z "$PLUGIN_VERSION" ]; then
        say "${RED}  x Could not read version from plugin.json${NC}"
        ERRORS=$((ERRORS + 1))
    elif [ "$PLUGIN_VERSION" != "$TARGET_VERSION" ]; then
        say "${RED}  x plugin.json version ($PLUGIN_VERSION) != target ($TARGET_VERSION)${NC}"
        say "${YELLOW}    Fix: Update .claude-plugin/plugin.json version to \"$TARGET_VERSION\"${NC}"
        ERRORS=$((ERRORS + 1))
    else
        say "${GREEN}  + plugin.json version matches: $PLUGIN_VERSION${NC}"
    fi
fi

# --------------------------------------------------------------------------
# Gate 2: validate-counts.sh green
# Expected counts come from scripts/config/counts.json (via lib/schema.sh)
# inside validate-counts.sh — never hardcoded here.
# --------------------------------------------------------------------------
echo ""
say "${CYAN}[2/5] Surface counts (validate-counts.sh)${NC}"

VALIDATE_COUNTS="$SCRIPT_DIR/validate-counts.sh"
if [ -f "$VALIDATE_COUNTS" ]; then
    vc_rc=0
    bash "$VALIDATE_COUNTS" || vc_rc=$?
    if [ "$vc_rc" -ne 0 ]; then
        say "${RED}  x validate-counts.sh failed (exit $vc_rc)${NC}"
        say "${YELLOW}    Fix: reconcile scripts/config/counts.json with the live surface,${NC}"
        say "${YELLOW}         then re-run bash scripts/validate-counts.sh${NC}"
        ERRORS=$((ERRORS + 1))
    else
        say "${GREEN}  + validate-counts.sh green${NC}"
    fi
else
    say "${YELLOW}  - validate-counts.sh not found (scaffold phase) — skipping${NC}"
fi

# --------------------------------------------------------------------------
# Gate 3: mkdocs build --strict (only if mkdocs.yml exists)
# --------------------------------------------------------------------------
echo ""
say "${CYAN}[3/5] Docs site build (mkdocs --strict)${NC}"

if [ -f "mkdocs.yml" ]; then
    if command -v mkdocs >/dev/null 2>&1; then
        mk_rc=0
        MK_OUT="$(mkdocs build --strict 2>&1)" || mk_rc=$?
        if [ "$mk_rc" -ne 0 ]; then
            say "${RED}  x mkdocs build --strict failed (exit $mk_rc)${NC}"
            printf '%s\n' "$MK_OUT" | tail -n 20 | sed 's/^/    /'
            ERRORS=$((ERRORS + 1))
        else
            say "${GREEN}  + mkdocs build --strict passed${NC}"
        fi
    else
        say "${RED}  x mkdocs.yml exists but mkdocs is not installed — gate cannot run${NC}"
        say "${YELLOW}    Fix: install mkdocs (pip install mkdocs) or run this check in CI${NC}"
        ERRORS=$((ERRORS + 1))
    fi
else
    say "${YELLOW}  - mkdocs.yml not found — skipping (no docs site yet)${NC}"
fi

# --------------------------------------------------------------------------
# Gate 4: Working tree clean (includes untracked files)
# --------------------------------------------------------------------------
echo ""
say "${CYAN}[4/5] Working tree status${NC}"

if git rev-parse --git-dir >/dev/null 2>&1; then
    DIRTY="$(git status --porcelain 2>/dev/null || true)"
    if [ -n "$DIRTY" ]; then
        say "${RED}  x Uncommitted/untracked changes detected:${NC}"
        printf '%s\n' "$DIRTY" | head -10 | sed 's/^/    /'
        say "${YELLOW}    Fix: commit or stash — the release tag must sit on a clean commit${NC}"
        ERRORS=$((ERRORS + 1))
    else
        say "${GREEN}  + Working tree clean${NC}"
    fi
else
    say "${YELLOW}  - Not a git repository — skipping tree check${NC}"
fi

# --------------------------------------------------------------------------
# Gate 5: CHANGELOG has the target version section
# Accepts "## [X.Y.Z]", "## X.Y.Z", and "## vX.Y.Z" heading forms.
# --------------------------------------------------------------------------
echo ""
say "${CYAN}[5/5] CHANGELOG section for v${TARGET_VERSION}${NC}"

VER_ESC="$(printf '%s' "$TARGET_VERSION" | sed 's/\./\\./g')"
if [ ! -f "CHANGELOG.md" ]; then
    say "${RED}  x CHANGELOG.md not found${NC}"
    say "${YELLOW}    Fix: create CHANGELOG.md with a \"## [$TARGET_VERSION]\" section${NC}"
    ERRORS=$((ERRORS + 1))
elif grep -E "^## +\[?v?${VER_ESC}\]?( |\$)" CHANGELOG.md >/dev/null 2>&1; then
    say "${GREEN}  + CHANGELOG.md has a section for v${TARGET_VERSION}${NC}"
else
    say "${RED}  x CHANGELOG.md has no section for v${TARGET_VERSION}${NC}"
    say "${YELLOW}    Fix: convert [Unreleased] to \"## [$TARGET_VERSION] - $(date +%Y-%m-%d)\"${NC}"
    ERRORS=$((ERRORS + 1))
fi

# --------------------------------------------------------------------------
# Summary
# --------------------------------------------------------------------------
echo ""
echo "==========================================="

if [ "$ERRORS" -gt 0 ]; then
    say "${RED}FAILED: $ERRORS error(s) found — fix before releasing v${TARGET_VERSION}${NC}"
    exit 1
else
    say "${GREEN}PASSED: Ready to release v${TARGET_VERSION}${NC}"
fi
