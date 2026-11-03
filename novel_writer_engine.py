"""Continuity-aware Novel Writer Engine.

This module prepares scene context, protects secrets from premature disclosure,
and checks draft text against approved canon and story chronology.

It intentionally does not call an LLM itself. The host application should pass
the generated prompt to its existing AI provider adapter, keeping API keys on
the server. All checks are advisory; semantic contradiction detection requires
human review.
"""
from __future__ import annotations
from dataclasses import dataclass, asdict
from typing import Any, Iterable
import re

@dataclass
class ContextBundle:
    project_id: str
    scene_goal: str
    pov_character: str | None
    scene_time: str | None
    location: str | None
    approved_facts: list[dict[str, Any]]
    relevant_characters: list[dict[str, Any]]
    relevant_events: list[dict[str, Any]]
    allowed_secrets: list[dict[str, Any]]
    withheld_secrets: list[dict[str, Any]]
    open_threads: list[str]
    continuity_warnings: list[str]

    def to_dict(self):
        return asdict(self)

def _norm(value: str | None) -> str:
    return re.sub(r"\s+", " ", (value or "").strip().casefold())

def _contains_any(text: str, terms: Iterable[str]) -> bool:
    normalized = _norm(text)
    return any(_norm(term) and _norm(term) in normalized for term in terms)

def build_scene_context(
    *,
    project_id: str,
    scene_goal: str,
    pov_character: str | None = None,
    scene_time: str | None = None,
    location: str | None = None,
    facts: list[dict] | None = None,
    characters: list[dict] | None = None,
    events: list[dict] | None = None,
    chapter_memories: list[dict] | None = None,
    secret_reveal_rules: dict[str, str] | None = None,
) -> ContextBundle:
    """Filter project memory into a scene-specific context bundle.

    secret_reveal_rules maps secret fact ID to the earliest permitted chapter
    label/number. A secret is included only when the current scene's chapter
    number is at or beyond that threshold. If no threshold is known, it stays
    withheld by default.
    """
    facts = facts or []
    characters = characters or []
    events = events or []
    chapter_memories = chapter_memories or []
    secret_reveal_rules = secret_reveal_rules or {}

    chapter_match = re.search(r"\d+", scene_time or "")
    current_chapter = int(chapter_match.group()) if chapter_match else None

    approved = [f for f in facts if f.get("status") == "approved"]
    secret_facts = [f for f in facts if f.get("status") == "secret"]
    allowed, withheld = [], []
    for fact in secret_facts:
        threshold = secret_reveal_rules.get(fact.get("id", ""))
        threshold_match = re.search(r"\d+", str(threshold)) if threshold is not None else None
        earliest = int(threshold_match.group()) if threshold_match else None
        if current_chapter is not None and earliest is not None and current_chapter >= earliest:
            allowed.append(fact)
        else:
            withheld.append(fact)

    # Keep only characters/events connected to the scene prompt or POV.
    scene_terms = [pov_character or "", location or "", scene_goal]
    relevant_characters = [
        c for c in characters
        if _contains_any(" ".join(scene_terms), [c.get("name", "")])
        or _contains_any(c.get("name", ""), [pov_character or ""])
    ]
    relevant_events = [
        e for e in events
        if _contains_any(" ".join(scene_terms), [e.get("title", ""), e.get("location", "")])
        or (scene_time and _norm(e.get("story_time")) == _norm(scene_time))
    ]

    open_threads = []
    for memory in chapter_memories:
        raw = memory.get("open_threads") or ""
        open_threads.extend([x.strip("- •\t ") for x in re.split(r"[\n;]+", raw) if x.strip("- •\t ")])

    warnings = []
    if withheld:
        warnings.append(f"{len(withheld)} secret fact(s) withheld because reveal timing is unknown or not reached.")
    if any(f.get("status") == "disputed" for f in facts):
        warnings.append("Disputed facts exist in project memory; do not treat them as established truth.")
    if not approved:
        warnings.append("No approved canon facts were supplied for this scene.")

    return ContextBundle(
        project_id=project_id,
        scene_goal=scene_goal,
        pov_character=pov_character,
        scene_time=scene_time,
        location=location,
        approved_facts=approved,
        relevant_characters=relevant_characters,
        relevant_events=relevant_events,
        allowed_secrets=allowed,
        withheld_secrets=withheld,
        open_threads=list(dict.fromkeys(open_threads)),
        continuity_warnings=warnings,
    )

def compose_scene_prompt(bundle: ContextBundle, style_guide: str = "") -> str:
    """Create a structured prompt for the configured AI provider."""
    data = bundle.to_dict()
    return f"""
You are the Novel Writer Engine inside NOVEL FORGE AI.
Write only the requested scene, not an outline or commentary.

SCENE OBJECTIVE
{data['scene_goal']}

POINT OF VIEW: {data['pov_character'] or "Use the project's established POV"}
STORY TIME: {data['scene_time'] or 'Follow the approved chronology'}
LOCATION: {data['location'] or 'Use the established location'}

APPROVED CANON (must not be contradicted):
{data['approved_facts']}

RELEVANT CHARACTERS:
{data['relevant_characters']}

RELEVANT EVENTS:
{data['relevant_events']}

SECRETS ALLOWED TO BE REVEALED NOW:
{data['allowed_secrets']}

STRICTLY WITHHELD SECRETS — NEVER reveal, hint at, paraphrase, or indirectly
confirm these in this scene:
{data['withheld_secrets']}

OPEN STORY THREADS:
{data['open_threads']}

CONTINUITY WARNINGS:
{data['continuity_warnings']}

STYLE GUIDE:
{style_guide or 'Follow the novel project style settings.'}

WRITING RULES:
- Preserve character knowledge: a character cannot act on information they do not know.
- Do not invent a backstory, relationship, date, object, or event that changes canon.
- Keep cause and effect clear; avoid convenient coincidences.
- Do not resolve open mysteries unless the scene objective explicitly requires it.
- Do not expose withheld secrets, even through dreams, metaphors, suspicious dialogue,
  omniscient narration, or misleading "almost-revelations".
- Advance character, conflict, or plot in every scene.
- Return polished literary prose only.
""".strip()

def check_draft_continuity(
    draft: str,
    *,
    approved_facts: list[dict] | None = None,
    withheld_secrets: list[dict] | None = None,
    required_terms: list[str] | None = None,
) -> dict:
    """Run transparent lexical checks and produce human-review flags.

    This is not a semantic truth detector. It catches direct mentions and
    missing required anchors; subtler contradictions must be reviewed.
    """
    draft_norm = _norm(draft)
    secret_hits = []
    for fact in withheld_secrets or []:
        probes = [fact.get("value", ""), fact.get("subject", "")]
        for probe in probes:
            probe_norm = _norm(probe)
            if len(probe_norm) >= 4 and probe_norm in draft_norm:
                secret_hits.append({"fact_id": fact.get("id"), "matched_text": probe})
    missing = [term for term in (required_terms or []) if _norm(term) and _norm(term) not in draft_norm]
    canon_subjects = [f.get("subject") for f in (approved_facts or []) if f.get("subject")]
    subject_mentions = [s for s in canon_subjects if _norm(s) in draft_norm]
    issues = []
    if secret_hits:
        issues.append("Possible premature secret disclosure detected.")
    if missing:
        issues.append("One or more required scene anchors are missing.")
    issues.append("Semantic continuity still requires editorial review; lexical checks cannot prove consistency.")
    return {
        "status": "needs_review" if secret_hits or missing else "review_required",
        "secret_leaks": secret_hits,
        "missing_required_terms": missing,
        "approved_canon_subjects_mentioned": subject_mentions,
        "issues": issues,
    }

def build_revision_brief(previous_text: str, new_text: str, author_instruction: str) -> str:
    """Create a safe revision instruction preserving all unrelated content."""
    return f"""
Revise the supplied scene according to the author's instruction.

AUTHOR INSTRUCTION:
{author_instruction}

PREVIOUS SCENE:
{previous_text}

CURRENT SCENE:
{new_text}

Requirements:
- Preserve all approved canon and continuity.
- Apply only the requested changes where possible.
- Do not silently remove plot clues, character motivations, or foreshadowing.
- Do not reveal any secret whose reveal point has not been reached.
- Return the complete revised scene, then a concise change log separately.
""".strip()
