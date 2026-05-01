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

## Remote Training Stack Smoke

The remote GPU box installed the latest available training stack into the virtual environment, not system Python:

```bash
/tmp/kan-unsloth-venv/bin/pip install --upgrade pip setuptools wheel
/tmp/kan-unsloth-venv/bin/pip install unsloth datasets trl accelerate peft transformers bitsandbytes
```

Observed installed versions:

- `unsloth-2026.4.8`
- `torch-2.10.0+cu128`
- `transformers-5.5.0`
- `trl-0.24.0`
- `accelerate-1.13.0`
- `peft-0.19.1`
- `bitsandbytes-0.49.2`

Smoke command:

```bash
/tmp/kan-unsloth-venv/bin/python -c "import torch; print(torch.__version__); print(torch.cuda.is_available()); print(torch.cuda.get_device_name(0)); import unsloth; print(getattr(unsloth, '__version__', 'unknown'))"
```

Result:

- CUDA available: `True`
- GPU: `NVIDIA GeForce RTX 4050 Laptop GPU`
- Unsloth import: `PASS`
- Note: Unsloth reported Flash Attention 2 was broken and used Xformers instead.
- Post-install dry run: `PASS`

## Limitation

No Unsloth training has been run yet. Do not claim the Unsloth prize until there is an adapter artifact and before/after benchmark. The RTX 4050 6 GB machine has a working CUDA/Unsloth stack, but its 6 GB VRAM is tight and should be treated as experimental for Gemma 4 QLoRA.
