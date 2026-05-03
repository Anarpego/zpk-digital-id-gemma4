# LiteRT-LM Gemma 4 Offline Evidence

Date: 2026-05-01

Purpose: verify a real offline Gemma 4 path using Google AI Edge LiteRT-LM,
separate from hosted Gemini API and separate from Android ML Kit/AICore.

## Runtime

- Host: Apple Silicon Mac, `arm64`
- Python isolation: `uv venv /private/tmp/zpk-litert-venv`
- Package installed in the venv: `litert-lm==0.10.1`
- Model source: `litert-community/gemma-4-E2B-it-litert-lm`
- Model file: `gemma-4-E2B-it.litertlm`
- Cached model path:
  `/Users/anibalperez/.cache/huggingface/hub/models--litert-community--gemma-4-E2B-it-litert-lm/snapshots/84b6978eff6e4eea02825bc2ee4ea48579f13109/gemma-4-E2B-it.litertlm`
- Model blob size: `2.4G`
- Model SHA-256:
  `ab7838cdfc8f77e54d8ca45eadceb20452d9f01e4bfade03e5dce27911b27e42`

## Commands

Install LiteRT-LM in a virtual environment:

```bash
uv venv /private/tmp/zpk-litert-venv
uv pip install --python /private/tmp/zpk-litert-venv/bin/python litert-lm
```

Initial download and run:

```bash
/private/tmp/zpk-litert-venv/bin/litert-lm run \
  --from-huggingface-repo litert-community/gemma-4-E2B-it-litert-lm \
  gemma-4-E2B-it.litertlm \
  --prompt 'Responde en JSON valido: {"summary":"explica en una frase por que ZPK mantiene el CUI local"}'
```

Offline rerun from the cached model path:

```bash
HF_HUB_OFFLINE=1 \
LITERT_LM_BIN=/private/tmp/zpk-litert-venv/bin/litert-lm \
LITERT_GEMMA4_MODEL_PATH=/Users/anibalperez/.cache/huggingface/hub/models--litert-community--gemma-4-E2B-it-litert-lm/snapshots/84b6978eff6e4eea02825bc2ee4ea48579f13109/gemma-4-E2B-it.litertlm \
./scripts/litert_gemma4_smoke.sh
```

## Output

The offline rerun returned:

```json
{"summary":"ZPK puede orientar sin internet porque Gemma corre local y el CUI no sale del dispositivo"}
```

## Trace Claim

This supports a new evidence claim:

```text
litert_gemma.model_hash(local) -> ab7838cdfc8f77e54d8ca45eadceb20452d9f01e4bfade03e5dce27911b27e42
litert_gemma.generate(gemma-4-E2B-it, HF_HUB_OFFLINE=1) -> ok
privacy_guard.raw_cui -> absent
```

## Boundary

This is real offline Gemma 4 local inference through LiteRT-LM on the Mac. It is
stronger than hosted-only evidence and matches the Google AI Edge direction. The
Flutter Android app now has a separate LiteRT-LM bridge, but the Mac emulator
does not yet provide successful Android in-app generation because its virtual
GPU/OpenCL path fails during decode.
