# Kan Unsloth Training Attempt

Date: 2026-05-01

Command:

```bash
HF_HUB_ENABLE_HF_TRANSFER=1 /tmp/kan-unsloth-venv/bin/python /tmp/kan-unsloth/unsloth/train_lora.py --run-name lora-smoke --max-seq-length 1024 --batch-size 1 --gradient-accumulation-steps 1 --max-steps 1
```

Environment:

- Remote virtual environment: `/tmp/kan-unsloth-venv`
- GPU: NVIDIA GeForce RTX 4050 Laptop GPU
- VRAM: 6,141 MiB total, about 5,771 MiB free before retry
- Unsloth: `2026.4.8`
- Torch: `2.10.0+cu128`
- Transformers: `5.5.0`
- Model: `unsloth/gemma-4-E2B-it-unsloth-bnb-4bit`

Result:

- Model slug resolved successfully.
- Model files downloaded successfully.
- Weights loaded successfully.
- Dataset formatting/tokenization completed for 6 examples.
- Training did not start because CUDA ran out of memory while Trainer moved the model to the GPU.

Failure excerpt:

```text
torch.OutOfMemoryError: CUDA out of memory. Tried to allocate 4.38 GiB. GPU 0 has a total capacity of 5.65 GiB of which 3.24 GiB is free.
```

Conclusion:

The scaffold is now compatible with the current model slug and TRL formatting API, but the available 6 GB RTX 4050 is not sufficient for even a one-step Gemma 4 E2B QLoRA smoke with this stack. Do not claim Unsloth prize readiness until training runs on a larger GPU and produces an adapter plus before/after evaluation.
