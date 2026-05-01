# Unsloth Scaffold Evidence

Date: 2026-05-01

Purpose: prepare, but not yet claim, an Unsloth fine-tuning path for Kan.

## Local Artifacts

- `unsloth/kan_legal_spanish_sft.jsonl`: 6 ShareGPT-style SFT examples.
- `unsloth/eval_cases.jsonl`: 3 held-out evaluation cases.
- `unsloth/train_lora.py`: dry-run validator plus lazy Unsloth training scaffold.
- `unsloth/pyproject.toml`: uv project with optional `train` dependencies.
- `unsloth/outputs/dry_run_report.md`: local dry-run result.

## Local Validation

Command:

```bash
cd unsloth
uv run python train_lora.py --dry-run
```

Result:

- Status: `PASS`
- SFT examples: 6
- Evaluation cases: 3

The command used a uv-created virtual environment, not system Python.

## Linux GPU Box Validation

Machine checked with:

```bash
ssh -i /Users/anibalperez/.ssh/id_ed25519 anarpego@192.168.0.17 nvidia-smi
```

Observed hardware:

- NVIDIA GeForce RTX 4050 Laptop GPU.
- 6,141 MiB VRAM.
- CUDA 12.8 driver stack.
- 15 GiB system RAM.
- About 230 GiB free disk.

Remote dry-run command used a virtual environment under `/tmp/kan-unsloth-venv`:

```bash
python3 -m venv /tmp/kan-unsloth-venv
/tmp/kan-unsloth-venv/bin/python /tmp/kan-unsloth/unsloth/train_lora.py --dry-run
```

Result:

- Status: `PASS`
- SFT examples: 6
- Evaluation cases: 3

## Limitation

No Unsloth training has been run yet. Do not claim the Unsloth prize until there is an adapter artifact and before/after benchmark. The RTX 4050 6 GB machine may be enough for a very small E2B QLoRA test, but it is tight and should be treated as experimental.
