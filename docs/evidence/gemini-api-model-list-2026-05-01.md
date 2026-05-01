# Gemini API Model List Evidence

Date: 2026-05-01

Purpose: verify that hosted Gemma 4 model IDs are available through the configured Gemini API key.

Command shape used, with key redacted:

```bash
set -a
source .env
set +a
curl -sS -H "x-goog-api-key: $GEMINI_API_KEY" \
  "https://generativelanguage.googleapis.com/v1beta/models"
```

Relevant returned model entries:

| API name | Display name |
|---|---|
| `models/gemma-4-26b-a4b-it` | Gemma 4 26B A4B IT |
| `models/gemma-4-31b-it` | Gemma 4 31B IT |

Other Gemma entries were also present, including Gemma 3 and Gemma 3n variants. This evidence supports using hosted Gemma 4 through the Gemini API while local Cactus evidence remains separate.
