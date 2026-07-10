"""
Structure + count validation for the folio plugin.

Mirrors craft's tests/test_craft_plugin.py pattern, scaled to folio's smaller
surface. Expected counts come from scripts/config/counts.json ONLY (single
source of truth, kept in sync via `bump-version.sh --counts-only`) — never
hardcoded here, so this suite doesn't need editing every time the roster
changes; only counts.json does.
"""

import json
import re
from pathlib import Path

import pytest
import yaml

REPO_ROOT = Path(__file__).parent.parent
COUNTS_JSON = REPO_ROOT / "scripts" / "config" / "counts.json"


def load_expected_counts() -> dict:
    return json.loads(COUNTS_JSON.read_text())


def find_all_commands() -> list[Path]:
    return sorted((REPO_ROOT / "commands").rglob("*.md"))


def find_all_skills() -> list[Path]:
    return sorted((REPO_ROOT / "skills").rglob("SKILL.md"))


def find_all_agents() -> list[Path]:
    return sorted((REPO_ROOT / "agents").rglob("*.md"))


def parse_frontmatter(path: Path) -> dict:
    """Extract and parse the YAML frontmatter block (between --- lines)."""
    text = path.read_text()
    match = re.match(r"^---\n(.*?)\n---\n", text, re.DOTALL)
    if not match:
        return {}
    return yaml.safe_load(match.group(1)) or {}


# --- Required project structure ---------------------------------------------


@pytest.mark.parametrize(
    "dirname", ["commands", "agents", "skills", "docs", "scripts", "tests"]
)
def test_required_dirs_exist(dirname):
    assert (REPO_ROOT / dirname).is_dir(), f"Missing required directory: {dirname}/"


def test_plugin_json_valid():
    plugin_json = REPO_ROOT / ".claude-plugin" / "plugin.json"
    assert plugin_json.is_file(), "Missing .claude-plugin/plugin.json"
    data = json.loads(plugin_json.read_text())
    for key in ("name", "version", "commands", "agents", "skills"):
        assert key in data, f"plugin.json missing required key: {key}"
    assert data["name"] == "folio"


# --- Counts (floor via scripts/config/counts.json, single source of truth) --


def test_command_count_matches_config():
    expected = load_expected_counts()["commands"]
    actual = len(find_all_commands())
    assert actual == expected, (
        f"Found {actual} commands, counts.json expects {expected} — "
        f"run `bump-version.sh --counts-only` if this surface change is intentional"
    )


def test_agent_count_matches_config():
    expected = load_expected_counts()["agents"]
    actual = len(find_all_agents())
    assert actual == expected, (
        f"Found {actual} agents, counts.json expects {expected} — "
        f"run `bump-version.sh --counts-only` if this surface change is intentional"
    )


def test_skill_count_matches_config():
    expected = load_expected_counts()["skills"]
    actual = len(find_all_skills())
    assert actual == expected, (
        f"Found {actual} skills, counts.json expects {expected} — "
        f"run `bump-version.sh --counts-only` if this surface change is intentional"
    )


# --- Frontmatter validity ----------------------------------------------------


@pytest.mark.parametrize("skill_path", find_all_skills(), ids=lambda p: p.parent.name)
def test_skill_frontmatter_has_name_and_description(skill_path):
    fm = parse_frontmatter(skill_path)
    assert "name" in fm, f"{skill_path} missing frontmatter 'name'"
    assert "description" in fm, f"{skill_path} missing frontmatter 'description'"
    assert len(fm["description"]) > 20, f"{skill_path} description too short to be useful"


@pytest.mark.parametrize("cmd_path", find_all_commands(), ids=lambda p: p.stem)
def test_command_frontmatter_has_description(cmd_path):
    fm = parse_frontmatter(cmd_path)
    assert "description" in fm, f"{cmd_path} missing frontmatter 'description'"


@pytest.mark.parametrize("agent_path", find_all_agents(), ids=lambda p: p.stem)
def test_agent_file_not_empty(agent_path):
    assert agent_path.stat().st_size > 100, f"{agent_path} looks empty/stub"
