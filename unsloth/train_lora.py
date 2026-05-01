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
TRAIN_REPORT_PATH = ROOT / "outputs" / "training_report.md"


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


def train(args: argparse.Namespace) -> int:
    # Heavy imports stay inside the training path so dry-run validation remains
    # usable on machines without CUDA or training dependencies installed.
    from unsloth import FastLanguageModel
    from datasets import load_dataset
    from trl import SFTConfig, SFTTrainer

    model, tokenizer = FastLanguageModel.from_pretrained(
        model_name=args.model_name,
        max_seq_length=args.max_seq_length,
        load_in_4bit=True,
    )
    model = FastLanguageModel.get_peft_model(
        model,
        r=args.lora_rank,
        target_modules=[
            "q_proj",
            "k_proj",
            "v_proj",
            "o_proj",
            "gate_proj",
            "up_proj",
            "down_proj",
        ],
        lora_alpha=args.lora_alpha,
        lora_dropout=0,
        bias="none",
        use_gradient_checkpointing="unsloth",
        random_state=3407,
    )

    dataset = load_dataset("json", data_files=str(SFT_PATH), split="train")
    output_dir = ROOT / "outputs" / args.run_name
    max_steps = args.max_steps if args.max_steps > 0 else -1

    def format_conversation(conversation: list[dict]) -> str:
        messages = []
        for turn in conversation:
            role = "user" if turn["from"] == "human" else "assistant"
            messages.append({"role": role, "content": turn["value"]})
        return tokenizer.apply_chat_template(
            messages,
            tokenize=False,
            add_generation_prompt=False,
        )

    def formatting_func(example: dict) -> list[str]:
        conversations = example["conversations"]
        if conversations and isinstance(conversations[0], list):
            return [format_conversation(conversation) for conversation in conversations]
        return [format_conversation(conversations)]

    trainer = SFTTrainer(
        model=model,
        processing_class=tokenizer,
        train_dataset=dataset,
        formatting_func=formatting_func,
        args=SFTConfig(
            output_dir=str(output_dir),
            max_seq_length=args.max_seq_length,
            per_device_train_batch_size=args.batch_size,
            gradient_accumulation_steps=args.gradient_accumulation_steps,
            num_train_epochs=args.epochs,
            max_steps=max_steps,
            learning_rate=args.learning_rate,
            logging_steps=1,
            save_strategy="epoch",
        ),
    )
    result = trainer.train()
    trainer.save_model(str(output_dir))

    TRAIN_REPORT_PATH.parent.mkdir(parents=True, exist_ok=True)
    TRAIN_REPORT_PATH.write_text(
        "\n".join(
            [
                "# Kan Unsloth Training Report",
                "",
                f"Model: `{args.model_name}`",
                f"Output: `{output_dir.relative_to(ROOT)}`",
                f"Max sequence length: {args.max_seq_length}",
                f"LoRA rank: {args.lora_rank}",
                f"Batch size: {args.batch_size}",
                f"Gradient accumulation: {args.gradient_accumulation_steps}",
                f"Epochs: {args.epochs}",
                f"Max steps: {max_steps}",
                f"Training loss: {result.training_loss}",
                "",
            ]
        ),
        encoding="utf-8",
    )
    return 0


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--dry-run", action="store_true", help="validate data only")
    parser.add_argument("--model-name", default="unsloth/gemma-4-E2B-it-unsloth-bnb-4bit")
    parser.add_argument("--run-name", default="lora")
    parser.add_argument("--max-seq-length", type=int, default=2048)
    parser.add_argument("--lora-rank", type=int, default=16)
    parser.add_argument("--lora-alpha", type=int, default=16)
    parser.add_argument("--batch-size", type=int, default=2)
    parser.add_argument("--gradient-accumulation-steps", type=int, default=4)
    parser.add_argument("--epochs", type=float, default=3)
    parser.add_argument("--max-steps", type=int, default=-1)
    parser.add_argument("--learning-rate", type=float, default=2e-4)
    args = parser.parse_args()
    return dry_run() if args.dry_run else train(args)


if __name__ == "__main__":
    raise SystemExit(main())
