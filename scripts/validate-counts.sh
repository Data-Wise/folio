#!/usr/bin/env bash
# validate-counts.sh - Validate folio command/agent/skill counts
#
# Adapted from craft's scripts/validate-counts.sh, folio-minimal:
#   - ALL counting + expected values go through scripts/lib/schema.sh
#     (single source of truth) — no inline find/grep counts here.
#   - Expected counts come from scripts/config/counts.json ONLY (never
#     hardcoded), so this script runs green on the empty 0/0/0 surface
#     today and Phase 2 just edits counts.json.
#   - plugin.json documented counts are compared only when the description
#     actually carries an "N commands|agents|skills" phrase (empty output
#     from folio_documented_plugin_count == "not documented, skip").
#
# Usage: ./scripts/validate-counts.sh
# Exit:  0 all counts match, 1 on any mismatch (with a clear diff message)
#
# Portability: bash 3.2 (macOS) + ubuntu CI. No jq (python3 via schema.sh).

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/lib/schema.sh"

# --- Colors (folio-minimal: inline, tty-aware, NO_COLOR honored) -----------
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    CYAN='\033[0;36m'
    NC='\033[0m'
else
    RED='' GREEN='' YELLOW='' CYAN='' NC=''
fi

printf "${CYAN}%s${NC}\n" "Folio Plugin Count Validation"
echo "============================="
echo ""

ERRORS=0

# --- Expected counts (scripts/config/counts.json — fail loudly if broken) --
EXP_CMDS="$(folio_expected_commands)" || {
    printf "${RED}%s${NC}\n" "Error: cannot read expected 'commands' from $FOLIO_COUNTS_JSON"
    exit 1
}
EXP_AGENTS="$(folio_expected_agents)" || {
    printf "${RED}%s${NC}\n" "Error: cannot read expected 'agents' from $FOLIO_COUNTS_JSON"
    exit 1
}
EXP_SKILLS="$(folio_expected_skills)" || {
    printf "${RED}%s${NC}\n" "Error: cannot read expected 'skills' from $FOLIO_COUNTS_JSON"
    exit 1
}

# --- Actual counts (filesystem, via schema.sh only) ------------------------
ACT_CMDS="$(folio_actual_commands)"
ACT_AGENTS="$(folio_actual_agents)"
ACT_SKILLS="$(folio_actual_skills)"

printf "${CYAN}%s${NC}\n" "Actual counts (from files):"
echo "  Commands: $ACT_CMDS"
echo "  Agents:   $ACT_AGENTS"
echo "  Skills:   $ACT_SKILLS"
echo ""
printf "${CYAN}%s${NC}\n" "Expected counts (scripts/config/counts.json):"
echo "  Commands: $EXP_CMDS"
echo "  Agents:   $EXP_AGENTS"
echo "  Skills:   $EXP_SKILLS"
echo ""

# check_pair LABEL ACTUAL EXPECTED SOURCE
check_pair() {
    if [ "$2" != "$3" ]; then
        printf "${RED}✗ %s mismatch: %s actual vs %s expected (%s)${NC}\n" \
            "$1" "$2" "$3" "$4"
        ERRORS=$((ERRORS + 1))
    else
        printf "${GREEN}✓ %s match: %s${NC}\n" "$1" "$2"
    fi
}

check_pair "Commands" "$ACT_CMDS"   "$EXP_CMDS"   "counts.json"
check_pair "Agents"   "$ACT_AGENTS" "$EXP_AGENTS" "counts.json"
check_pair "Skills"   "$ACT_SKILLS" "$EXP_SKILLS" "counts.json"
echo ""

# --- Per-category command counts (tracked categories only) -----------------
printf "${CYAN}%s${NC}\n" "Command breakdown by category:"
for cat in $FOLIO_CMD_SCAN_CATEGORIES; do
    act="$(folio_actual_category_commands "$cat")"
    if exp="$(folio_expected_category "$cat" 2>/dev/null)"; then
        if [ "$act" != "$exp" ]; then
            printf "  ${RED}✗ %-8s %s actual vs %s expected${NC}\n" "$cat:" "$act" "$exp"
            ERRORS=$((ERRORS + 1))
        else
            printf "  ${GREEN}✓ %-8s %s${NC}\n" "$cat:" "$act"
        fi
    else
        # Scan-only category (e.g. "root" until Phase 2 tracks it)
        printf "  %-10s %s (scan-only, not tracked in counts.json)\n" "$cat:" "$act"
    fi
done
echo ""

# --- Documented counts (plugin.json description — skip when absent) --------
DOC_CMDS="$(folio_documented_plugin_count commands)"
DOC_AGENTS="$(folio_documented_plugin_count agents)"
DOC_SKILLS="$(folio_documented_plugin_count skills)"

if [ -n "$DOC_CMDS$DOC_AGENTS$DOC_SKILLS" ]; then
    printf "${CYAN}%s${NC}\n" "Documented counts (plugin.json description):"
    [ -n "$DOC_CMDS" ]   && check_pair "Commands (documented)" "$ACT_CMDS"   "$DOC_CMDS"   "plugin.json"
    [ -n "$DOC_AGENTS" ] && check_pair "Agents (documented)"   "$ACT_AGENTS" "$DOC_AGENTS" "plugin.json"
    [ -n "$DOC_SKILLS" ] && check_pair "Skills (documented)"   "$ACT_SKILLS" "$DOC_SKILLS" "plugin.json"
    echo ""
else
    printf "${YELLOW}%s${NC}\n" "⚠ plugin.json carries no count phrases yet — skipping documented-count check"
    echo ""
fi

# --- Verdict ----------------------------------------------------------------
if [ "$ERRORS" -gt 0 ]; then
    printf "${YELLOW}%s${NC}\n" "Found $ERRORS count discrepancy(ies)."
    echo ""
    echo "  If the surface changed intentionally, update scripts/config/counts.json:"
    echo "    {\"commands\": $ACT_CMDS, \"agents\": $ACT_AGENTS, \"skills\": $ACT_SKILLS, ...}"
    echo "  and keep plugin.json description phrases in sync."
    exit 1
fi

printf "${GREEN}%s${NC}\n" "All counts validated!"
exit 0
