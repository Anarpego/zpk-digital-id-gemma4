#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ROOT}/.env"
MODEL="${GEMMA_MODEL:-gemma-4-31b-it}"
PROMPT="${1:-Responde en espanol claro, maximo 40 palabras: Que debe hacer una persona en Guatemala si descubre que su CUI aparece en una brecha de datos?}"

if [[ -f "${ENV_FILE}" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "${ENV_FILE}"
  set +a
fi

if [[ -z "${GEMINI_API_KEY:-}" ]]; then
  echo "GEMINI_API_KEY is required in .env or environment" >&2
  exit 2
fi

request_body="$(
  jq -n --arg prompt "${PROMPT}" '{
    contents: [
      {
        parts: [
          {
            text: $prompt
          }
        ]
      }
    ],
    generationConfig: {
      temperature: 0.2,
      maxOutputTokens: 120
    }
  }'
)"

curl -sS \
  -H "x-goog-api-key: ${GEMINI_API_KEY}" \
  -H "Content-Type: application/json" \
  "https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:generateContent" \
  -d "${request_body}"
