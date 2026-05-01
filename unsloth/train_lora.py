#!/usr/bin/env python3
"""Unsloth LoRA training scaffold for Kan.

Run the dry validation path first:

    uv run python train_lora.py --dry-run

The actual training path imports heavy ML dependencies lazily so dataset checks
can run in a clean uv environment without installing GPU packages.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parent
SFT_PATH = ROOT / "kan_legal_spanish_sft.jsonl"
EVAL_PATH = ROOT / "eval_cases.jsonl"
REPORT_PATH = ROOT / "outputs" / "dry_run_report.md"


def read_jsonl(path: Path) -> list[dict]:
    rows: list[dict] = []
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


def validate_sft(rows: list[dict]) -> list[str]:
    issues: list[str] = []
    for index, row in enumerate(rows, start=1):
        conversations = row.get("conversations")
        if not isinstance(conversations, list) or len(conversations) < 2:
            issues.append(f"sft row {index}: missing two-turn conversations")
            continue
        roles = [turn.get("from") for turn in conversations]
        if roles[:2] != ["human", "gpt"]:
            issues.append(f"sft row {index}: expected human -> gpt")
        for turn in conversations:
            if not isinstance(turn.get("value"), str) or not turn["value"].strip():
                issues.append(f"sft row {index}: empty turn value")
    return issues


def validate_eval(rows: list[dict]) -> list[str]:
    issues: list[str] = []
    for index, row in enumerate(rows, start=1):
        for key in ("id", "scenario", "input", "must_include", "must_not_include"):
            if key not in row:
                issues.append(f"eval row {index}: missing {key}")
        if not isinstance(row.get("must_include"), list):
            issues.append(f"eval row {index}: must_include must be a list")
        if not isinstance(row.get("must_not_include"), list):
            issues.append(f"eval row {index}: must_not_include must be a list")
    return issues


def write_report(sft_rows: list[dict], eval_rows: list[dict], issues: list[str]) -> None:
    REPORT_PATH.parent.mkdir(parents=True, exist_ok=True)
    status = "PASS" if not issues else "FAIL"
    report = [
        "# Kan Unsloth Dry-Run Report",
        "",
        f"Status: {status}",
        f"SFT examples: {len(sft_rows)}",
        f"Evaluation cases: {len(eval_rows)}",
        "",
        "## Checks",
        "",
        "- ShareGPT-style SFT rows parse as JSONL.",
        "- Evaluation rows include required rubric fields.",
        "- No training was executed in dry-run mode.",
    ]
    if issues:
        report.extend(["", "## Issues", ""])
        report.extend(f"- {issue}" for issue in issues)
    REPORT_PATH.write_text("\n".join(report) + "\n", encoding="utf-8")


def dry_run() -> int:
    sft_rows = read_jsonl(SFT_PATH)
    eval_rows = read_jsonl(EVAL_PATH)
    issues = [*validate_sft(sft_rows), *validate_eval(eval_rows)]
    write_report(sft_rows, eval_rows, issues)
    print(REPORT_PATH)
    return 1 if issues else 0


def train() -> int:
    # Heavy imports stay inside the training path so dry-run validation remains
    # usable on machines without CUDA or training dependencies installed.
    from datasets import load_dataset
    from trl import SFTConfig, SFTTrainer
    from unsloth import FastLanguageModel

    model_name = "unsloth/gemma-4-E2B-it-bnb-4bit"
    max_seq_length = 2048

    model, tokenizer = FastLanguageModel.from_pretrained(
        model_name=model_name,
        max_seq_length=max_seq_length,
        load_in_4bit=True,
    )
    model = FastLanguageModel.get_peft_model(
        model,
        r=16,
        target_modules=[
            "q_proj",
            "k_proj",
            "v_proj",
            "o_proj",
            "gate_proj",
            "up_proj",
            "down_proj",
        ],
        lora_alpha=16,
        lora_dropout=0,
        bias="none",
        use_gradient_checkpointing="unsloth",
        random_state=3407,
    )

    dataset = load_dataset("json", data_files=str(SFT_PATH), split="train")
    trainer = SFTTrainer(
        model=model,
        tokenizer=tokenizer,
        train_dataset=dataset,
        args=SFTConfig(
            output_dir=str(ROOT / "outputs" / "lora"),
            max_seq_length=max_seq_length,
            per_device_train_batch_size=2,
            gradient_accumulation_steps=4,
            num_train_epochs=3,
            learning_rate=2e-4,
            logging_steps=1,
            save_strategy="epoch",
        ),
    )
    trainer.train()
    trainer.save_model(str(ROOT / "outputs" / "lora"))
    return 0


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--dry-run", action="store_true", help="validate data only")
    args = parser.parse_args()
    return dry_run() if args.dry_run else train()


if __name__ == "__main__":
    raise SystemExit(main())
