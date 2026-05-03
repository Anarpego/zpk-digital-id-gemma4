#!/usr/bin/env python3
"""Validate ZPK synthetic SFT/distillation datasets before training."""

from __future__ import annotations

import argparse
import json
import re
from collections import Counter
from pathlib import Path


ROOT = Path(__file__).resolve().parent
DATA_DIR = ROOT / "data"
REPORT = ROOT / "outputs" / "dataset_quality_report.md"
PII_PATTERN = re.compile(r"(?<!\d)\d{13}(?!\d)")
REQUIRED_ASSISTANT_KEYS = {
    "summary",
    "next_steps",
    "national_scale_note",
    "safety_review",
}


def read_jsonl(path: Path) -> list[dict]:
    rows = []
    with path.open("r", encoding="utf-8") as handle:
        for line_number, line in enumerate(handle, start=1):
            line = line.strip()
            if not line:
                continue
            try:
                rows.append(json.loads(line))
            except json.JSONDecodeError as exc:
                raise ValueError(f"{path}:{line_number}: invalid JSON") from exc
    return rows


def assistant_json(row: dict) -> dict:
    messages = row.get("messages")
    if not isinstance(messages, list) or len(messages) < 3:
        raise ValueError("missing messages")
    assistant = messages[-1]
    if assistant.get("role") != "assistant":
        raise ValueError("last message must be assistant")
    content = assistant.get("content")
    if not isinstance(content, str):
        raise ValueError("assistant content must be text")
    decoded = json.loads(content)
    if not isinstance(decoded, dict):
        raise ValueError("assistant JSON must be object")
    return decoded


def validate_row(row: dict, seen_ids: set[str]) -> list[str]:
    issues: list[str] = []
    row_id = row.get("id")
    if not isinstance(row_id, str) or not row_id:
        issues.append("missing id")
    elif row_id in seen_ids:
        issues.append(f"duplicate id {row_id}")
    else:
        seen_ids.add(row_id)

    raw = json.dumps(row, ensure_ascii=False)
    if PII_PATTERN.search(raw):
        issues.append(f"{row_id}: contains 13-digit identifier")

    metadata = row.get("metadata")
    if not isinstance(metadata, dict) or metadata.get("contains_real_personal_data") is not False:
        issues.append(f"{row_id}: metadata must mark no real personal data")

    try:
        payload = assistant_json(row)
    except (ValueError, json.JSONDecodeError) as exc:
        issues.append(f"{row_id}: {exc}")
        return issues

    missing = REQUIRED_ASSISTANT_KEYS.difference(payload)
    if missing:
        issues.append(f"{row_id}: assistant JSON missing {sorted(missing)}")
    if payload.get("safety_review", {}).get("raw_cui_included") is not False:
        issues.append(f"{row_id}: raw_cui_included must be false")
    next_steps = payload.get("next_steps")
    if not isinstance(next_steps, list) or not (2 <= len(next_steps) <= 5):
        issues.append(f"{row_id}: next_steps must contain 2-5 items")
    return issues


def validate_split(path: Path, seen_ids: set[str]) -> tuple[list[dict], list[str], Counter]:
    rows = read_jsonl(path)
    issues: list[str] = []
    scenarios: Counter = Counter()
    for row in rows:
        issues.extend(validate_row(row, seen_ids))
        scenario = row.get("metadata", {}).get("scenario")
        if isinstance(scenario, str):
            scenarios[scenario] += 1
    return rows, issues, scenarios


def write_report(split_counts: dict[str, int], scenarios: Counter, issues: list[str]) -> None:
    REPORT.parent.mkdir(parents=True, exist_ok=True)
    lines = [
        "# ZPK Dataset Quality Report",
        "",
        f"Status: {'PASS' if not issues else 'FAIL'}",
        "",
        "## Splits",
        "",
        *[f"- {name}: {count}" for name, count in split_counts.items()],
        "",
        "## Scenario Distribution",
        "",
        *[f"- {name}: {count}" for name, count in sorted(scenarios.items())],
        "",
        "## Checks",
        "",
        "- JSONL parses.",
        "- IDs are unique across splits.",
        "- Assistant content is strict JSON.",
        "- No 13-digit identifiers appear.",
        "- Metadata marks rows as synthetic and without real personal data.",
        "- `safety_review.raw_cui_included` is false.",
    ]
    if issues:
        lines.extend(["", "## Issues", ""])
        lines.extend(f"- {issue}" for issue in issues[:200])
    REPORT.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--data-dir", type=Path, default=DATA_DIR)
    args = parser.parse_args()

    paths = {
        "train": args.data_dir / "zpk_gt_latam_sft_train.jsonl",
        "validation": args.data_dir / "zpk_gt_latam_sft_validation.jsonl",
        "test": args.data_dir / "zpk_gt_latam_sft_test.jsonl",
    }
    seen_ids: set[str] = set()
    all_issues: list[str] = []
    split_counts: dict[str, int] = {}
    scenario_counts: Counter = Counter()
    for name, path in paths.items():
        rows, issues, scenarios = validate_split(path, seen_ids)
        split_counts[name] = len(rows)
        all_issues.extend(issues)
        scenario_counts.update(scenarios)

    write_report(split_counts, scenario_counts, all_issues)
    print(REPORT)
    return 1 if all_issues else 0


if __name__ == "__main__":
    raise SystemExit(main())
