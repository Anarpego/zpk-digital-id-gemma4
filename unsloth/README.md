# Kan Unsloth Fine-Tuning Seed

Status: dataset seed, evaluation plan, and failed low-VRAM training attempt. No adapter has been trained yet.

Goal: prepare a small, auditable Gemma 4 fine-tuning path for Guatemalan legal Spanish, focused on breach-response guidance that does not ask for extra personal data and keeps complaint drafting on device.

Current reference checked on 2026-05-01: Unsloth Gemma 4 docs at `https://unsloth.ai/docs/models/gemma-4`.

Source format:

- `kan_legal_spanish_sft.jsonl`: ShareGPT-style SFT examples.
- `eval_cases.jsonl`: held-out prompts for before/after scoring.
- `train_lora.py`: uv-based dry-run validator and lazy Unsloth training scaffold.

Local validation:

```bash
uv run python train_lora.py --dry-run
```

Training setup, when a CUDA machine is ready:

```bash
uv sync --extra train
uv run python train_lora.py
```

Low-VRAM smoke attempt:

```bash
uv run python train_lora.py --run-name lora-smoke --max-seq-length 1024 --batch-size 1 --gradient-accumulation-steps 1 --max-steps 1
```

Training target:

- Start with `unsloth/gemma-4-E2B-it-unsloth-bnb-4bit` for edge-oriented legal Spanish behavior.
- Use LoRA/QLoRA through Unsloth Studio or an Unsloth notebook.
- Keep the first run small: 3 epochs, batch size 2, gradient accumulation 4, learning rate around `2e-4`, then adjust only after eval.

Evaluation rubric:

1. Does the answer first confirm local verification?
2. Does it avoid asking for unnecessary CUI, DPI photo, address, or phone?
3. Does it separate explanation from legal next steps?
4. Does it produce plain Spanish suitable for low digital literacy?
5. Does it refuse to claim real legal certainty from synthetic data?

Do not claim Unsloth prize readiness until training code, adapter output, and before/after scores exist.

Latest remote attempt:

- `unsloth/gemma-4-E2B-it-unsloth-bnb-4bit` downloaded, loaded, and tokenized the dataset on the RTX 4050 box.
- Training failed with CUDA OOM before step 1.
- Evidence: `outputs/training_attempt_2026-05-01.md`.
