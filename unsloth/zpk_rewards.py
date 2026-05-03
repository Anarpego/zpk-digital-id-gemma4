"""Reward functions for optional GRPO/RLKD-style ZPK adaptation.

These are lightweight, deterministic rewards that mirror the app contract.
They can be plugged into TRL GRPO scripts later, or used offline to score
candidate generations from Gemma 4 teacher/student models.
"""

from __future__ import annotations

import json
import re
from difflib import SequenceMatcher
from typing import Any


PII_PATTERN = re.compile(r"(?<!\d)\d{13}(?!\d)")
REQUIRED_KEYS = {
    "summary",
    "next_steps",
    "national_scale_note",
    "safety_review",
}
OFFLINE_TERMS = ("offline", "local", "dispositivo", "sin enviar")
ACTION_TERMS = (
    "evidencia",
    "paquete",
    "redactado",
    "bloqueo",
    "revocar",
    "auditoria",
)


def parse_json_response(text: str) -> dict[str, Any] | None:
    text = text.strip()
    start = text.find("{")
    end = text.rfind("}")
    if start == -1 or end <= start:
        return None
    try:
        decoded = json.loads(text[start : end + 1])
    except json.JSONDecodeError:
        return None
    return decoded if isinstance(decoded, dict) else None


def zpk_contract_reward(completions: list[str], **_: Any) -> list[float]:
    return [score_zpk_contract(text) for text in completions]


def score_zpk_contract(text: str) -> float:
    payload = parse_json_response(text)
    if payload is None:
        return 0.0

    score = 0.0
    if REQUIRED_KEYS.issubset(payload):
        score += 0.25
    if payload.get("safety_review", {}).get("raw_cui_included") is False:
        score += 0.20
    if not PII_PATTERN.search(json.dumps(payload, ensure_ascii=False)):
        score += 0.20
    if _contains_any(payload, OFFLINE_TERMS):
        score += 0.15
    if _contains_any(payload, ACTION_TERMS):
        score += 0.15
    next_steps = payload.get("next_steps")
    if isinstance(next_steps, list) and 2 <= len(next_steps) <= 5:
        score += 0.05
    return min(score, 1.0)


def structured_distillation_reward(
    student_steps: list[dict[str, str]],
    teacher_steps: list[dict[str, str]],
) -> float:
    """Approximate RLKD step alignment without a learned reward model.

    Each step has `meta_reasoning`, `subproblem`, and `solution`. We reward
    sequential agreement and stop at the first weak meta-reasoning alignment,
    following the early-exit spirit of the RLKD structured reward mechanism.
    """
    total = 0.0
    max_total = max(len(teacher_steps), 1)
    for student, teacher in zip(student_steps, teacher_steps):
        meta = _similarity(student.get("meta_reasoning", ""), teacher.get("meta_reasoning", ""))
        if meta < 0.45:
            break
        subproblem = _similarity(student.get("subproblem", ""), teacher.get("subproblem", ""))
        solution = _similarity(student.get("solution", ""), teacher.get("solution", ""))
        total += (0.50 * meta) + (0.25 * subproblem) + (0.25 * solution)
    return min(total / max_total, 1.0)


def _contains_any(payload: dict[str, Any], terms: tuple[str, ...]) -> bool:
    text = json.dumps(payload, ensure_ascii=False).lower()
    return any(term in text for term in terms)


def _similarity(left: str, right: str) -> float:
    return SequenceMatcher(None, left.lower().strip(), right.lower().strip()).ratio()
