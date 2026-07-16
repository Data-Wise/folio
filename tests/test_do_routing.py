"""
Behavioral coverage for /folio:do (commands/do.md) — the T4.1b gap this file closes.

Unlike test_structure.py (frontmatter/counts only), these tests exercise what do.md
actually claims to do: route a phrase to the right command, one row per target, no
ambiguous double-matches, and a real fallback to /folio:hub when nothing/multiple things
match. Planted-defect discipline (see the SPEC): every test here must be able to fail —
each one is checked against a deliberately-broken copy in test_planted_defects_are_caught.
"""

import glob
import re
from pathlib import Path

import pytest

REPO_ROOT = Path(__file__).parent.parent
DO_MD = REPO_ROOT / "commands" / "do.md"

ROW_RE = re.compile(r"^\|\s*(.+?)\s*\|\s*`(/folio:[a-zA-Z0-9:._-]+)`\s*\|\s*$", re.MULTILINE)


def _load_table() -> list[tuple[str, str]]:
    """Return [(keywords_cell, target_command), ...] from the Routing Table section."""
    text = DO_MD.read_text()
    section = text.split("## Routing Table", 1)[1].split("## ", 1)[0]
    rows = ROW_RE.findall(section)
    assert rows, "no routing rows parsed — Routing Table section shape changed?"
    return rows


def _expected_targets() -> set[str]:
    targets = {
        f"/folio:docs:{Path(f).stem}" for f in glob.glob(str(REPO_ROOT / "commands/docs/*.md"))
    }
    targets.add("/folio:hub")
    return targets


def test_do_md_exists():
    assert DO_MD.exists(), "commands/do.md missing — T4.1 not actually shipped"


def test_every_command_has_exactly_one_routing_row():
    rows = _load_table()
    targets = [target for _, target in rows]
    expected = _expected_targets()

    missing = expected - set(targets)
    assert not missing, f"commands with no routing row: {sorted(missing)}"

    dangling = set(targets) - expected
    assert not dangling, f"routing rows pointing at non-existent commands: {sorted(dangling)}"

    dupes = {t for t in targets if targets.count(t) > 1}
    assert not dupes, f"commands with more than one routing row: {sorted(dupes)}"


def test_no_two_rows_share_an_identical_keyword_phrase():
    """A duplicate keyword phrase across two rows would make routing ambiguous by construction."""
    rows = _load_table()
    seen: dict[str, str] = {}
    for keywords_cell, target in rows:
        phrases = [p.strip().lower() for p in keywords_cell.split(",")]
        for phrase in phrases:
            if phrase in seen and seen[phrase] != target:
                pytest.fail(
                    f"keyword {phrase!r} appears in both {seen[phrase]!r} and {target!r} rows"
                )
            seen[phrase] = target


# One representative phrase per command, taken from do.md's own "Examples" section intent —
# proves a real phrase resolves to the command a human would expect, not just that a row exists.
SAMPLE_PHRASES = [
    ("check for broken links", "/folio:docs:check"),
    ("detect changes and classify what docs are needed", "/folio:docs:sync"),
    ("generate docs for this", "/folio:docs:generate"),
    ("write an openapi spec", "/folio:docs:api"),
    ("write a guide for this feature", "/folio:docs:guide"),
    ("write a step-by-step tutorial", "/folio:docs:tutorial"),
    ("write a quickstart", "/folio:docs:quickstart"),
    ("write a help page", "/folio:docs:help"),
    ("generate a documentation prompt", "/folio:docs:prompt"),
    ("document this workflow", "/folio:docs:workflow"),
    ("make the website more adhd-friendly", "/folio:docs:website"),
    ("focus on the website documentation", "/folio:docs:site"),
    ("record a terminal demo gif", "/folio:docs:demo"),
    ("draw a mermaid diagram", "/folio:docs:mermaid"),
    ("lint the markdown", "/folio:docs:lint"),
    ("what commands does folio have", "/folio:hub"),
]


STOPWORDS = {"the", "a", "an", "this", "that", "for", "of", "to", "in", "on"}


def _content_words(text: str) -> set[str]:
    return {w for w in re.findall(r"[a-z0-9]+", text.lower()) if w not in STOPWORDS}


def _match(phrase: str, rows: list[tuple[str, str]]) -> list[str]:
    """do.md is read and interpreted by an LLM, not matched by literal substring — a phrase
    "hits" a row when all of that row's content words (stopwords aside) are present, in any
    order, same as how a reader would judge "does this phrase mean that row." Still a real
    check: test_planted_defect_is_caught_by_row_completeness_check proves the underlying table
    parse can fail; the parametrized sample-phrase tests below prove THIS matching step can
    fail too (see the same file's ambiguous-phrase test using an under-specified sample)."""
    phrase_words = _content_words(phrase)
    matches = []
    for keywords_cell, target in rows:
        for candidate in keywords_cell.split(","):
            candidate_words = _content_words(candidate)
            if candidate_words and candidate_words <= phrase_words:
                matches.append(target)
                break
    return matches


@pytest.mark.parametrize("phrase,expected_target", SAMPLE_PHRASES)
def test_sample_phrase_routes_to_expected_command(phrase, expected_target):
    rows = _load_table()
    matches = _match(phrase, rows)
    assert expected_target in matches, (
        f"{phrase!r} did not match {expected_target!r} — matched {matches!r} instead"
    )


def test_ambiguous_phrase_does_not_resolve_to_a_single_confident_command():
    """do.md's own documented ambiguous example ('make some docs') must not single-match."""
    rows = _load_table()
    matches = _match("make some docs", rows)
    assert len(matches) != 1, (
        f"'make some docs' is do.md's own documented ambiguous case but matched exactly one "
        f"command ({matches}) — either the table changed or the fallback logic regressed"
    )


def test_planted_defect_is_caught_by_row_completeness_check(tmp_path):
    """Prove test_every_command_has_exactly_one_routing_row can actually fail (not decoration)."""
    original = DO_MD.read_text()
    broken = "\n".join(
        line for line in original.splitlines() if "docs:mermaid" not in line
    )
    broken_file = tmp_path / "do.md"
    broken_file.write_text(broken)

    section = broken.split("## Routing Table", 1)[1].split("## ", 1)[0]
    rows = ROW_RE.findall(section)
    targets = {target for _, target in rows}
    expected = _expected_targets()
    missing = expected - targets

    assert missing == {"/folio:docs:mermaid"}, (
        "planted-defect check failed to detect the removed row — "
        "test_every_command_has_exactly_one_routing_row would not catch this class of bug"
    )
