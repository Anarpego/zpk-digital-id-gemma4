#!/usr/bin/env python3
"""Evaluate ZPK ReAct-format datasets with the four metrics declared in
apptowin.md section 9.2:

- json_validity_rate: fraction of assistant turns that are valid JSON.
- react_format_rate: fraction that respect {action,tool,input} or
  {action:final,...}.
- pii_leak_rate: fraction of rows containing 13-digit identifiers anywhere.
- tool_chain_completeness: fraction of conversations that reach a `final`
  decision without infinite loops.

Writes a markdown report to outputs/react_dataset_quality_report.md.
"""

from __future__ import annotations

import argparse
import json
import re
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parent
DEFAULT_DATA = ROOT / "data" / "react"
REPORT = ROOT / "outputs" / "react_dataset_quality_report.md"
PII_PATTERN = re.compile(r"(?<!\d)\d{13}(?!\d)")


def read_jsonl(path: Path) -> list[dict]:
    rows = []
    with path.open("r", encoding="utf-8") as h:
        for line_no, line in enumerate(h, 1):
            line = line.strip()
            if not line:
                continue
            try:
                rows.append(json.loads(line))
            except json.JSONDecodeError as exc:
                raise ValueError(f"{path}:{line_no}: invalid JSON line") from exc
    return rows


def assistant_turns(row: dict) -> list[str]:
    msgs = row.get("messages", [])
    return [m["content"] for m in msgs
            if m.get("role") == "assistant" and isinstance(m.get("content"), str)]


def is_valid_json(text: str) -> bool:
    try:
        json.loads(text)
        return True
    except json.JSONDecodeError:
        return False


def is_react_shaped(text: str) -> bool:
    try:
        decoded = json.loads(text)
    except json.JSONDecodeError:
        return False
    if not isinstance(decoded, dict):
        return False
    action = decoded.get("action")
    if action == "tool_call":
        return isinstance(decoded.get("tool"), str) and isinstance(decoded.get("input"), dict)
    if action == "final":
        return (isinstance(decoded.get("summary"), str)
                and isinstance(decoded.get("next_steps"), list)
                and 2 <= len(decoded["next_steps"]) <= 6)
    return False


def reaches_final(row: dict) -> bool:
    for content in assistant_turns(row):
        try:
            decoded = json.loads(content)
        except json.JSONDecodeError:
            continue
        if isinstance(decoded, dict) and decoded.get("action") == "final":
            return True
    return False


def has_pii_leak(row: dict) -> bool:
    raw = json.dumps(row, ensure_ascii=False)
    return bool(PII_PATTERN.search(raw))


def evaluate_split(path: Path) -> dict:
    rows = read_jsonl(path)
    n_rows = len(rows)
    n_assistant_turns = 0
    n_valid_json = 0
    n_react_shaped = 0
    n_with_final = 0
    n_with_leak = 0
    scenario_counter: Counter = Counter()

    for row in rows:
        scenario = row.get("metadata", {}).get("scenario", "unknown")
        scenario_counter[scenario] += 1
        if has_pii_leak(row):
            n_with_leak += 1
        if reaches_final(row):
            n_with_final += 1
        for content in assistant_turns(row):
            n_assistant_turns += 1
            if is_valid_json(content):
                n_valid_json += 1
            if is_react_shaped(content):
                n_react_shaped += 1

    return {
        "rows": n_rows,
        "assistant_turns": n_assistant_turns,
        "json_validity_rate": _safe_div(n_valid_json, n_assistant_turns),
        "react_format_rate": _safe_div(n_react_shaped, n_assistant_turns),
        "tool_chain_completeness": _safe_div(n_with_final, n_rows),
        "pii_leak_rate": _safe_div(n_with_leak, n_rows),
        "scenarios": dict(scenario_counter),
    }


def _safe_div(a: int, b: int) -> float:
    return round(a / b, 4) if b else 0.0


def write_report(per_split: dict[str, dict]) -> None:
    REPORT.parent.mkdir(parents=True, exist_ok=True)
    lines = ["# ZPK ReAct Dataset Quality Report", ""]

    overall_pass = True
    for name, m in per_split.items():
        if not (m["json_validity_rate"] >= 0.99
                and m["react_format_rate"] >= 0.99
                and m["tool_chain_completeness"] >= 0.99
                and m["pii_leak_rate"] == 0.0):
            overall_pass = False

    lines.append(f"Status: {'PASS' if overall_pass else 'FAIL'}")
    lines.append("")
    for name, m in per_split.items():
        lines.append(f"## {name}")
        lines.append("")
        lines.append(f"- rows: {m['rows']}")
        lines.append(f"- assistant_turns: {m['assistant_turns']}")
        lines.append(f"- json_validity_rate: {m['json_validity_rate']}")
        lines.append(f"- react_format_rate: {m['react_format_rate']}")
        lines.append(f"- tool_chain_completeness: {m['tool_chain_completeness']}")
        lines.append(f"- pii_leak_rate: {m['pii_leak_rate']}")
        lines.append("- scenarios:")
        for sc, ct in sorted(m["scenarios"].items()):
            lines.append(f"  - {sc}: {ct}")
        lines.append("")
    lines.append("## Thresholds")
    lines.append("")
    lines.append("- json_validity_rate >= 0.99")
    lines.append("- react_format_rate >= 0.99")
    lines.append("- tool_chain_completeness >= 0.99")
    lines.append("- pii_leak_rate == 0.0")
    REPORT.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--data-dir", type=Path, default=DEFAULT_DATA)
    args = parser.parse_args()

    paths = {
        "train": args.data_dir / "zpk_react_lote1_train.jsonl",
        "validation": args.data_dir / "zpk_react_lote1_validation.jsonl",
        "test": args.data_dir / "zpk_react_lote1_test.jsonl",
    }
    per_split = {name: evaluate_split(p) for name, p in paths.items()}
    write_report(per_split)
    print(REPORT)
    for name, m in per_split.items():
        print(f"{name}: rows={m['rows']} json={m['json_validity_rate']} "
              f"react={m['react_format_rate']} chain={m['tool_chain_completeness']} "
              f"leak={m['pii_leak_rate']}")

    fail = any(
        m["json_validity_rate"] < 0.99
        or m["react_format_rate"] < 0.99
        or m["tool_chain_completeness"] < 0.99
        or m["pii_leak_rate"] > 0.0
        for m in per_split.values()
    )
    return 1 if fail else 0


if __name__ == "__main__":
    raise SystemExit(main())
