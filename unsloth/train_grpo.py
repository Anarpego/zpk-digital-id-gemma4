#!/usr/bin/env python3
"""Optional GRPO/RLKD-style training for ZPK Gemma 4 adaptation.

This is a real training entrypoint, but it requires a CUDA Linux machine with
the `train` extra installed. The reward is deterministic and mirrors the
production app contract: valid JSON, no CUI leak, offline boundary, and
actionable redacted handoff.
"""

from __future__ import annotations

import argparse
from pathlib import Path

from zpk_rewards import zpk_contract_reward


ROOT = Path(__file__).resolve().parent
DATA_DIR = ROOT / "data"
PROMPT_PATH = DATA_DIR / "zpk_gt_latam_grpo_prompts.jsonl"


def build_prompt_dataset() -> Path:
    import json

    source = DATA_DIR / "zpk_gt_latam_sft_train.jsonl"
    output = PROMPT_PATH
    output.parent.mkdir(parents=True, exist_ok=True)
    with source.open("r", encoding="utf-8") as src, output.open(
        "w",
        encoding="utf-8",
    ) as dst:
        for line in src:
            row = json.loads(line)
            messages = row["messages"][:2]
            dst.write(
                json.dumps(
                    {
                        "id": row["id"],
                        "prompt": messages,
                        "scenario": row["metadata"]["scenario"],
                    },
                    ensure_ascii=False,
                    sort_keys=True,
                )
                + "\n"
            )
    return output


def train(args: argparse.Namespace) -> int:
    # Heavy imports stay lazy so dataset tooling works without CUDA packages.
    from datasets import load_dataset
    from trl import GRPOConfig, GRPOTrainer
    from unsloth import FastLanguageModel
    import torch

    prompt_path = build_prompt_dataset()
    dataset = load_dataset("json", data_files=str(prompt_path), split="train")

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

    output_dir = ROOT / "outputs" / args.run_name
    config = GRPOConfig(
        output_dir=str(output_dir),
        learning_rate=args.learning_rate,
        per_device_train_batch_size=args.batch_size,
        gradient_accumulation_steps=args.gradient_accumulation_steps,
        max_prompt_length=args.max_prompt_length,
        max_completion_length=args.max_completion_length,
        num_generations=args.num_generations,
        max_steps=args.max_steps,
        logging_steps=1,
        save_steps=args.save_steps,
        bf16=torch.cuda.is_available() and torch.cuda.is_bf16_supported(),
        fp16=torch.cuda.is_available() and not torch.cuda.is_bf16_supported(),
    )
    trainer = GRPOTrainer(
        model=model,
        processing_class=tokenizer,
        reward_funcs=[zpk_contract_reward],
        args=config,
        train_dataset=dataset,
    )
    trainer.train()
    trainer.save_model(str(output_dir))
    return 0


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--model-name", default="unsloth/gemma-4-E2B-it-unsloth-bnb-4bit")
    parser.add_argument("--run-name", default="grpo-zpk-contract")
    parser.add_argument("--max-seq-length", type=int, default=2048)
    parser.add_argument("--max-prompt-length", type=int, default=1024)
    parser.add_argument("--max-completion-length", type=int, default=512)
    parser.add_argument("--lora-rank", type=int, default=16)
    parser.add_argument("--lora-alpha", type=int, default=16)
    parser.add_argument("--batch-size", type=int, default=1)
    parser.add_argument("--gradient-accumulation-steps", type=int, default=8)
    parser.add_argument("--num-generations", type=int, default=4)
    parser.add_argument("--max-steps", type=int, default=200)
    parser.add_argument("--save-steps", type=int, default=50)
    parser.add_argument("--learning-rate", type=float, default=5e-6)
    args = parser.parse_args()
    return train(args)


if __name__ == "__main__":
    raise SystemExit(main())
