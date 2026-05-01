# Gemma 4 API Smoke Evidence

Date: 2026-05-01

Purpose: verify real Gemma 4 access for the Kan hackathon submission without deploying infrastructure.

## Verified Endpoint

- API: Gemini API `generateContent`
- Model requested: `gemma-4-31b-it`
- Model returned: `gemma-4-31b-it`
- Authentication: local `.env` contained `GEMINI_API_KEY`; the key was not printed or committed.
- Repeatable script: `scripts/gemma4_smoke.sh`

## Prompt

```text
Responde en espanol claro, maximo 40 palabras: Que debe hacer una persona en Guatemala si descubre que su CUI aparece en una brecha de datos?
```

## Final Model Answer

```text
Monitorea tus cuentas bancarias y trámites oficiales. Cambia contraseñas, activa la verificación en dos pasos y denuncia el incidente ante el Ministerio Público. Mantente alerta ante llamadas o correos sospechosos para evitar fraudes de identidad.
```

## Metadata

- Prompt tokens: 35
- Candidate tokens: 51
- Total tokens: 526
- Thoughts tokens: 440
- Finish reason: `MAX_TOKENS`

## Notes

The response included a `thought` part before the final answer. This is useful video/writeup evidence for Gemma 4 reasoning, but the app should show only user-safe summaries unless the demo intentionally shows a reasoning trace.

This evidence proves hosted Gemma 4 access. It does not prove on-device Gemma 4 inference.
