# ZPK Gemma 4 Adaptation Pipeline

Status: production-oriented adaptation pipeline and failed low-VRAM training attempt. No adapter has been trained yet.

Goal: prepare an auditable Gemma 4 fine-tuning and optional RLKD/GRPO path for Guatemala and Latin America, focused on identity recovery, extortion evidence preservation, economic fraud/remittance triage, and redacted institutional handoff. The data is synthetic by design and must not include real CUI, phone numbers, addresses, victims, or case files.

References checked on 2026-05-02:

- Unsloth docs: local model running/training, LoRA, RL, and export support.
- TRL `SFTTrainer`: conversational `messages` format, packing, eval split, assistant-only loss.
- PEFT LoRA/QLoRA guidance: train adapters instead of all model weights; QLoRA-style all-linear/attention-MLP targets where supported.
- RLKD paper `arXiv:2505.16142v4`: SFT distillation can imitate surface reasoning, while structured rewards can teach meta-reasoning and solving alignment.

Source format:

- `data/zpk_gt_latam_sft_train.jsonl`: generated TRL conversational SFT train split.
- `data/zpk_gt_latam_sft_validation.jsonl`: validation split.
- `data/zpk_gt_latam_sft_test.jsonl`: held-out test split.
- `data/zpk_gt_latam_rlkd_teacher.jsonl`: structured teacher traces for RLKD-style scoring.
- `kan_legal_spanish_sft.jsonl`: legacy small ShareGPT seed.
- `eval_cases.jsonl`: held-out hand-written prompts.
- `generate_guatemala_latam_sft.py`: deterministic synthetic data generator.
- `evaluate_dataset.py`: leakage, JSON contract, split, and scenario validation.
- `distill_with_gemma4_teacher.py`: teacher-structure trace builder. Default is local deterministic; optional Gemma API teacher requires `GEMINI_API_KEY`.
- `zpk_rewards.py`: deterministic reward functions for app-contract and structured-distillation scoring.
- `train_lora.py`: LoRA/QLoRA SFT path.
- `train_grpo.py`: optional GRPO path using the app-contract reward.

Local validation:

```bash
uv run python generate_guatemala_latam_sft.py --examples 12000
uv run python evaluate_dataset.py
uv run python distill_with_gemma4_teacher.py --teacher local --limit 1200
uv run python train_lora.py --dry-run
```

SFT training setup, when a CUDA Linux machine is ready:

```bash
uv sync --extra train
uv run python train_lora.py \
  --dataset generated \
  --run-name zpk-gt-latam-lora \
  --max-seq-length 2048 \
  --batch-size 1 \
  --gradient-accumulation-steps 8 \
  --epochs 2 \
  --packing \
  --assistant-only-loss
```

Optional GRPO/RLKD-style contract training after SFT:

```bash
uv run python train_grpo.py \
  --run-name zpk-gt-latam-grpo \
  --batch-size 1 \
  --gradient-accumulation-steps 8 \
  --num-generations 4 \
  --max-steps 200
```

Training target:

- Start with `unsloth/gemma-4-E2B-it-unsloth-bnb-4bit` for edge-oriented legal Spanish behavior.
- Use LoRA/QLoRA through Unsloth. Keep the base frozen and train adapters.
- Start conservative on a laptop GPU: batch size 1, gradient accumulation 8, sequence length 2048, LoRA rank 16, learning rate `2e-4` for SFT and `5e-6` for GRPO.
- Use validation loss and held-out safety tests before any claim.

Evaluation rubric:

1. Does the answer first confirm local verification?
2. Does it avoid asking for unnecessary CUI, DPI photo, address, or phone?
3. Does it separate explanation from legal next steps?
4. Does it produce plain Spanish suitable for low digital literacy?
5. Does it refuse to claim real legal certainty from synthetic data?
6. Does it produce valid JSON accepted by the Flutter app contract?
7. Does it separate internet bootstrap from offline identity action?
8. Does it cover identity recovery, extortion evidence, economic fraud, and preventive wallet flows?

Do not claim Unsloth prize readiness until training code, adapter output, and before/after scores exist.

Latest remote attempt:

- `unsloth/gemma-4-E2B-it-unsloth-bnb-4bit` downloaded, loaded, and tokenized the dataset on the RTX 4050 box.
- Training failed with CUDA OOM before step 1.
- Evidence: `outputs/training_attempt_2026-05-01.md`.
