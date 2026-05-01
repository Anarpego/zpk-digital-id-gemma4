# Kan Hackathon Winning Plan

## Current Decision

The competition goal overrides implementation preferences in `kan.md` when they conflict. As of May 1, 2026, the strongest path is a mobile-first, offline-capable demo that visibly proves privacy, local Gemma 4 use, function calling, and document generation. Server infrastructure and PostgreSQL 18 are useful only after the core demo works.

## Prize Targets

- Main prize: show a complete citizen story, not just architecture.
- Digital Equity & Inclusivity: Spanish-first, low-literacy guidance, voice-ready flows, Android-first.
- Cactus Prize: local-first mobile routing between on-device Gemma 4 E4B and optional server reasoning.
- Unsloth Prize: domain adapter and before/after benchmark if time allows.
- Safety & Trust upside: explain post-quantum-ready credentials as the Bacab/Kan future path, while keeping today's prototype usable.

## Technical Adjustment

Use SQLite/local assets for breach lookup and legal templates in the demo. PostgreSQL 18 remains valid for a production server, but it must not block offline functionality or video evidence.

Use Training-Free GRPO from arXiv:2510.08191 as a low-cost prompt/experience optimization layer before expensive fine-tuning. Keep a small experience library for tool-use behavior, compare multiple rollouts on synthetic cases, and bake the distilled rules into the local reasoner prompt. This can improve demo quality even before the Unsloth adapter is ready.

Use post-quantum cryptography in the narrative and architecture only where it strengthens trust without slowing the demo. The practical first step is a visible "future credential security" section and later ML-DSA credential signing in Bacab, not cryptographic complexity in the first mobile flow.

## Next Working Milestones

1. Runnable Flutter app with offline synthetic breach verification and complaint preview.
2. Tests proving invalid CUI, exposed CUI, and no-network behavior.
3. Replace mock reasoner boundary with Cactus/Gemma service.
4. Add Unsloth dataset/notebook and benchmark report.
5. Add server only for abstract legal reasoning and public transparency demo.
6. Add a short post-quantum credential security note to the writeup/video script.
