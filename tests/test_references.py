"""
Every /craft:<name> and /folio:<name> cited in commands/, skills/ and agents/ must resolve.

folio was split out of craft (v4.0.0), and 76 citations of craft commands that no longer
exist survived the split (folio#24). This test keeps that drift from returning.

- /folio:<name> resolves to commands/docs/<stem>.md (as docs:<stem>), or to hub or do.
- /craft:<name> resolves against tests/data/craft_commands.txt, a pinned list (folio's tests
  cannot read another repo). The file's header records the craft commit and the refresh command.
- tests/data/reference_allowlist.txt holds known offenders as `path :: reference` pairs. It is
  meant to shrink to retired-command notes only; an entry that no longer matches fails the suite.
- Planted-defect discipline: test_planted_defects_are_caught proves the scan can fail.

Run `python3 tests/test_references.py` to print the unresolved count with an empty allowlist.
"""

import re
import sys
from pathlib import Path

import pytest

REPO_ROOT = Path(__file__).parent.parent
DATA = Path(__file__).parent / "data"
SCAN_DIRS = ("commands", "skills", "agents")
REF_RE = re.compile(r"/(craft|folio):([a-z][a-z0-9:-]*)")
PLACEHOLDER_RE = re.compile(r"command\d*")


def load_craft_commands() -> set[str]:
    return {
        line.strip()
        for line in (DATA / "craft_commands.txt").read_text().splitlines()
        if line.strip() and not line.startswith("#")
    }


def load_allowlist() -> set[tuple[str, str]]:
    pairs = set()
    for line in (DATA / "reference_allowlist.txt").read_text().splitlines():
        if line.strip() and not line.startswith("#"):
            path, ref = (part.strip() for part in line.split("::", 1))
            pairs.add((path, ref))
    return pairs


def folio_commands(root: Path) -> set[str]:
    names = {f"docs:{p.stem}" for p in (root / "commands" / "docs").glob("*.md")}
    return names | {"hub", "do"}


def find_references(root: Path):
    """Yield (relative path, reference like '/craft:site:build', line number) for each citation."""
    for scan_dir in SCAN_DIRS:
        for path in sorted((root / scan_dir).rglob("*.md")):
            rel = path.relative_to(root).as_posix()
            for lineno, line in enumerate(path.read_text().splitlines(), 1):
                for match in REF_RE.finditer(line):
                    if line[match.end() : match.end() + 1] == "*":
                        continue  # glob such as /folio:docs:*
                    name = match.group(2).rstrip(":-")
                    if PLACEHOLDER_RE.fullmatch(name):
                        continue  # documentation placeholder such as /craft:command1
                    yield rel, f"/{match.group(1)}:{name}", lineno


def find_unresolved(root: Path, craft: set[str], allowlist=frozenset()):
    folio = folio_commands(root)
    bad = []
    for rel, ref, lineno in find_references(root):
        plugin, name = ref[1:].split(":", 1)
        known = craft if plugin == "craft" else folio
        if name not in known and (rel, ref) not in allowlist:
            bad.append((rel, ref, lineno))
    return bad


def test_craft_list_is_pinned_with_provenance():
    header = (DATA / "craft_commands.txt").read_text().splitlines()[:3]
    assert any("craft commit:" in line for line in header), "record the craft commit in the header"
    assert len(load_craft_commands()) > 20


def test_references_resolve():
    bad = find_unresolved(REPO_ROOT, load_craft_commands(), load_allowlist())
    assert not bad, "unresolved references (fix them, or allowlist retired-command notes):\n" + "\n".join(
        f"  {rel}:{lineno} {ref}" for rel, ref, lineno in bad
    )


def test_allowlist_has_no_stale_entries():
    craft, folio = load_craft_commands(), folio_commands(REPO_ROOT)
    present = {(rel, ref) for rel, ref, _ in find_references(REPO_ROOT)}
    stale = []
    for rel, ref in sorted(load_allowlist()):
        plugin, name = ref[1:].split(":", 1)
        known = craft if plugin == "craft" else folio
        if (rel, ref) not in present or name in known:
            stale.append(f"  {rel} :: {ref}")
    assert not stale, "allowlist entries that no longer apply (delete them):\n" + "\n".join(stale)


def test_planted_defects_are_caught(tmp_path):
    (tmp_path / "commands" / "docs").mkdir(parents=True)
    (tmp_path / "skills").mkdir()
    (tmp_path / "agents").mkdir()
    (tmp_path / "commands" / "docs" / "real.md").write_text(
        "See /folio:docs:real, /folio:hub, /craft:check, and the glob /folio:docs:* and /craft:command1.\n"
    )
    (tmp_path / "commands" / "docs" / "bad.md").write_text(
        "Run /craft:site:nothing then /folio:docs:nothing.\n"
    )
    craft = {"check"}
    bad = find_unresolved(tmp_path, craft)
    assert {(rel, ref) for rel, ref, _ in bad} == {
        ("commands/docs/bad.md", "/craft:site:nothing"),
        ("commands/docs/bad.md", "/folio:docs:nothing"),
    }
    allowed = {("commands/docs/bad.md", "/craft:site:nothing"), ("commands/docs/bad.md", "/folio:docs:nothing")}
    assert find_unresolved(tmp_path, craft, allowed) == []


if __name__ == "__main__":
    bad = find_unresolved(REPO_ROOT, load_craft_commands())
    print(f"{len(bad)} unresolved occurrences in {len({b[0] for b in bad})} files, "
          f"{len({(b[0], b[1]) for b in bad})} distinct (file, reference) pairs")
    sys.exit(1 if bad else 0)
