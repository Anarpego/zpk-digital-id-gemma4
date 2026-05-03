#!/usr/bin/env bash
set -euo pipefail

MODEL_REPO="${LITERT_GEMMA4_REPO:-litert-community/gemma-4-E2B-it-litert-lm}"
MODEL_FILE="${LITERT_GEMMA4_FILE:-gemma-4-E2B-it.litertlm}"
LITERT_BIN="${LITERT_LM_BIN:-litert-lm}"
PROMPT="${1:-Responde solo JSON valido sin Markdown: {\"summary\":\"ZPK puede orientar sin internet porque Gemma corre local y el CUI no sale del dispositivo\"}}"

if [[ -n "${LITERT_GEMMA4_MODEL_PATH:-}" ]]; then
  MODEL_REF="$LITERT_GEMMA4_MODEL_PATH"
  export HF_HUB_OFFLINE="${HF_HUB_OFFLINE:-1}"
  "$LITERT_BIN" run "$MODEL_REF" --prompt "$PROMPT"
else
  "$LITERT_BIN" run \
    --from-huggingface-repo "$MODEL_REPO" \
    "$MODEL_FILE" \
    --prompt "$PROMPT"
fi
