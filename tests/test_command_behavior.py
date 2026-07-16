"""
Behavioral coverage for folio's 15 commands/docs/*.md + hub.md — the other half of the
T4.1b gap (do.md's own routing behavior is covered separately in test_do_routing.py).

test_structure.py proves a command *exists* with valid frontmatter. These tests prove each
command's *content* does what it claims: declared arguments are actually used in the body
(an argument nobody reads is a dead declaration, likely a copy-paste leftover), file paths
referenced in the body resolve on disk (a stale reference silently breaks at runtime, not at
review time), and the body has real instructional substance, not just a frontmatter stub.
"""

import re
from pathlib import Path

import pytest
import yaml

REPO_ROOT = Path(__file__).parent.parent
FRONTMATTER_RE = re.compile(r"^---\n(.*?)\n---\n(.*)$", re.DOTALL)


def find_all_commands() -> list[Path]:
    return sorted((REPO_ROOT / "commands").rglob("*.md"))


def parse(path: Path) -> tuple[dict, str]:
    match = FRONTMATTER_RE.match(path.read_text())
    assert match, f"{path}: no frontmatter block found"
    fm = yaml.safe_load(match.group(1)) or {}
    body = match.group(2)
    return fm, body


ALL_COMMANDS = find_all_commands()
ALL_COMMAND_IDS = [str(p.relative_to(REPO_ROOT)) for p in ALL_COMMANDS]


@pytest.mark.parametrize("cmd_path", ALL_COMMANDS, ids=ALL_COMMAND_IDS)
def test_command_has_substantive_body(cmd_path):
    """A command file that's frontmatter + a one-line title isn't a real command yet."""
    _, body = parse(cmd_path)
    non_blank_lines = [l for l in body.splitlines() if l.strip()]
    assert len(non_blank_lines) >= 10, (
        f"{cmd_path.relative_to(REPO_ROOT)}: body has only {len(non_blank_lines)} non-blank "
        f"lines — looks like a stub, not real instructions"
    )
    assert re.search(r"^##\s", body, re.MULTILINE), (
        f"{cmd_path.relative_to(REPO_ROOT)}: no '## ' section found in body"
    )


@pytest.mark.parametrize("cmd_path", ALL_COMMANDS, ids=ALL_COMMAND_IDS)
def test_declared_arguments_are_referenced_in_body(cmd_path):
    """An argument declared in frontmatter but never mentioned in the body is dead weight."""
    fm, body = parse(cmd_path)
    args = fm.get("arguments") or []
    body_lower = body.lower()
    unreferenced = []
    for arg in args:
        name = arg.get("name")
        alias = arg.get("alias")
        if not name:
            continue
        needles = [name.lower(), name.replace("-", " ").lower(), name.replace("-", "_").lower()]
        if alias:
            needles.append(alias.lower())
        if not any(n in body_lower for n in needles):
            unreferenced.append(name)
    assert not unreferenced, (
        f"{cmd_path.relative_to(REPO_ROOT)}: arguments declared but never referenced in body: "
        f"{unreferenced}"
    )


REF_PATTERN = re.compile(r"`((?:commands|skills|agents)/[^`\s]+\.md)`")


@pytest.mark.parametrize("cmd_path", ALL_COMMANDS, ids=ALL_COMMAND_IDS)
def test_referenced_files_exist(cmd_path):
    """commands/skills/agents paths named in a command body must resolve on disk."""
    _, body = parse(cmd_path)
    missing = []
    for match in REF_PATTERN.finditer(body):
        ref = match.group(1)
        if "*" in ref or "<" in ref:
            continue
        if not (REPO_ROOT / ref).exists():
            missing.append(ref)
    assert not missing, (
        f"{cmd_path.relative_to(REPO_ROOT)}: references non-existent files: {missing}"
    )


def test_planted_defect_is_caught_by_substantive_body_check(tmp_path):
    """Prove the stub-detection check can actually fail on a real stub, not just pass by luck."""
    stub = "---\ndescription: stub\n---\n\n# Stub Command\n\nTODO.\n"
    stub_path = tmp_path / "stub.md"
    stub_path.write_text(stub)
    _, body = parse(stub_path)
    non_blank_lines = [l for l in body.splitlines() if l.strip()]
    assert len(non_blank_lines) < 10, "planted stub unexpectedly looks substantive"
