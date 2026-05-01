# Kan — Full Implementation Context

> This document is a complete context brief intended to be provided to a coding LLM (Claude, GPT, Gemini, or any other) so it can help implement the Kan application. It is dense, technical, and opinionated. It assumes the implementing engineer is competent and the LLM is capable. Treat every section as binding unless explicitly marked as a tradeoff or open question.

---

## How to use this document

Paste this entire document into the system prompt or first message of an LLM coding assistant. Then ask for specific deliverables: a Phoenix module, a Flutter widget, a Dockerfile, a deployment script, a test suite. The LLM should treat this document as ground truth for product scope, architecture, naming, and constraints. If asked to deviate from anything here, the LLM should flag it explicitly and ask for confirmation before generating code that violates these decisions.

---

## Table of contents

1. [Product summary](#1-product-summary)
2. [What we are optimizing for: winning the hackathon](#2-what-we-are-optimizing-for-winning-the-hackathon)
3. [Hackathon requirements: full reference](#3-hackathon-requirements-full-reference)
4. [Target user, explicitly](#4-target-user-explicitly)
5. [The problem in concrete numbers](#5-the-problem-in-concrete-numbers)
6. [The three core flows](#6-the-three-core-flows)
7. [Architecture: split-tier inference with privacy preservation](#7-architecture-split-tier-inference-with-privacy-preservation)
8. [Tech stack summary table](#8-tech-stack-summary-table)
9. [Project structure](#9-project-structure)
10. [Data model](#10-data-model)
11. [Function-calling tools](#11-function-calling-tools)
12. [Real-time UX with Phoenix LiveView and Channels](#12-real-time-ux-with-phoenix-liveview-and-channels)
13. [Privacy and security commitments](#13-privacy-and-security-commitments)
14. [PostgreSQL 18 tuning for Kan](#14-postgresql-18-tuning-for-kan)
15. [Deployment topology](#15-deployment-topology)
16. [Local development setup](#16-local-development-setup)
17. [Testing strategy](#17-testing-strategy)
18. [The 18-day plan](#18-the-18-day-plan)
19. [What Kan deliberately is not](#19-what-kan-deliberately-is-not)
20. [Open questions and risks](#20-open-questions-and-risks)
21. [Coding conventions and constraints](#21-coding-conventions-and-constraints)
22. [The narrative anchor](#22-the-narrative-anchor)
23. [Final instructions to the implementing LLM](#23-final-instructions-to-the-implementing-llm)

---

## 1. Product summary

**Kan** is a mobile citizen-facing application that helps Guatemalan citizens defend themselves against the consequences of large-scale data breaches affecting government and private institutions. It does three sequential things:

1. **Detection.** Determines whether the user's personal data appears in known public breaches.
2. **Explanation.** Communicates what the breach means in plain accessible Spanish, primarily through voice.
3. **Action.** Generates the legally correct complaint document for the user's specific case, tells them which fiscalía (prosecutor's office) to visit, and gives them a printable PDF with their data already filled in.

**The name Kan** comes from Mayan languages where it means "serpent" — associated in Maya cosmology with knowledge, vigilance, and protection (the feathered serpent Kukulkán/Q'uq'umatz as guardian). It is short, pronounceable in Spanish without ambiguity, and culturally rooted without being a cliché.

**Sister project: Bacab.** Kan is the ciudadano-facing app. Bacab is the broader identity infrastructure project (citizen identity platform with WebAuthn, ML-DSA credentials, ZK proofs). Kan today protects citizens from existing breaches. When Bacab Identity ships, the same Kan app becomes the wallet for Bacab credentials. The two share narrative arc but Kan ships first and stands alone.

**Hackathon context.** Kan is being built for the Gemma 4 Good Hackathon. The submission requires: a 3-minute video, public code repo, live demo, Kaggle writeup under 1500 words. Deadline is 18 days from Apr 30, 2026. The submission targets three of the five tracks: Digital Equity & Inclusivity, Safety & Trust, Global Resilience.

---

## 2. What we are optimizing for: winning the hackathon

This section is explicit because it shapes every other decision in the document.

**Primary objective: win the Gemma 4 Good Hackathon.** Not build the most cost-efficient system. Not build the most architecturally elegant system. Not build the most scalable system. Win the hackathon. Every decision in this document should be evaluated against that goal.

This means several things in practice:

1. **Use Google's official path for Gemma.** Google AI Studio over OpenRouter, even though OpenRouter offers provider redundancy. Vertex AI later, if needed, but stay in Google's ecosystem. The judges are aligned with Google. Alignment is a free advantage.

2. **Use the largest Gemma model that fits the constraint.** Gemma 4 31B IT Thinking on the server, not 26B A4B, even though 26B is cheaper to run. The marginal benchmark improvements (Arena AI 1452 vs 1441, AIME 2026 89.2% vs 88.3%) translate to noticeably better demo quality, which is what judges see.

3. **Showcase the new Gemma 4 capabilities prominently.** Native function calling. Multimodal vision (DPI OCR from photo). Thinking mode visualized in the UI. Audio input on E4B. Each of these is a hackathon point, not just a technical detail.

4. **Privacy as a feature, not a footnote.** The hackathon explicitly mentions "where privacy is non-negotiable" in its problem framing. The split-tier inference architecture is a literal answer to that line. Make it visible: in the writeup, in the video, in the demo.

5. **The video is the submission.** The Kaggle writeup is judged. The code is verified. But the 3-minute video is what wins. Optimize the demo for video: slow enough that judges can follow, real enough that it feels authentic, visually clear so the Gemma 4 capabilities are obvious.

6. **The narrative beats the architecture.** A grandmother in Petén who walks out with a printed denuncia is more memorable than a system with elegant module boundaries. Both matter, but if there is a tradeoff, narrative wins.

7. **Honest scoping.** Single language (Spanish). Three flows. One device target (Android). One server stack. Do these excellently rather than ten things mediocrely. The hackathon rewards depth over breadth in 18 days.

When a future LLM working on Kan faces a tradeoff and the documentation seems to favor a less optimal technical choice, the answer is here: **the technical decision was made to win the hackathon**. After May 18, 2026, decisions can be revisited. Until then, hackathon optimization is the priority.

---

## 3. Hackathon requirements: full reference

This section reproduces the binding details of the Gemma 4 Good Hackathon so the implementing LLM has them as ground truth. If anything in this document conflicts with what the hackathon actually requires, the hackathon requirements win — verify against `https://www.kaggle.com/competitions/gemma-4-good-hackathon` if uncertain.

### Mission and framing

The hackathon's stated mission: build a solution that addresses a real-world challenge using Gemma 4 models, whether an application that helps millions or a specialized model that could exponentially scale innovation. The framing emphasizes *"building for the places that need it most"* — examples given include classrooms with spotty internet, medical sites far from data centers, and communities where privacy is non-negotiable. **Kan is a textbook fit for the third example.**

### The full prize structure: $200,000 total

The hackathon offers $200K across three concurrent tracks. **Projects are eligible to win both a Main Track Prize and a Special Technology Prize** — explicit text from the rules. This means Kan can target multiple prizes simultaneously if the architecture genuinely justifies them.

#### Main Track ($100,000)

For the best overall projects demonstrating exceptional vision, technical execution, and potential for real-world impact.

- **First Prize: $50,000**
- **Second Prize: $25,000**
- **Third Prize: $15,000**
- **Fourth Prize: $10,000**

#### Impact Track ($50,000) — one prize per submission

$10,000 per category. A submission selects one Impact Track. **Kan's choice: Digital Equity & Inclusivity.**

- Health & Sciences ($10K)
- Global Resilience ($10K)
- Future of Education ($10K)
- **Digital Equity & Inclusivity ($10K) ← Kan's selection.** *"Break down barriers through linguistic diversity, intuitive interfaces, and tools that help close the AI skills gap."* Kan's voice-first interface, accessible Spanish, and Android 8-10 support are textbook fits.
- Safety & Trust ($10K)

#### Special Technology Track ($50,000) — multiple prizes possible

$10,000 per category. Projects can win multiple Special Technology Prizes if they genuinely use multiple technologies.

- **Cactus Prize ($10K) ← Kan targets this.** *"For the best local-first mobile or wearable application that intelligently routes tasks between models."* This describes Kan's split-tier inference architecture (E4B on device, 31B on server) literally word for word. Cactus shipped day-one Gemma 4 support and provides a Flutter SDK with on-device/cloud routing built in.
- LiteRT Prize ($10K) — incompatible with Cactus; Kan does not target this.
- llama.cpp Prize ($10K) — for resource-constrained hardware. Kan does not target this.
- Ollama Prize ($10K) — for local Gemma 4 via Ollama. Kan rejected Ollama in favor of Google AI Studio. Does not target this.
- **Unsloth Prize ($10K) ← Kan targets this.** *"For the best fine-tuned Gemma 4 model created using Unsloth, optimized for a specific, impactful task."* Kan fine-tunes Gemma 4 E4B on a curated dataset of Guatemalan legal language, accessible Spanish for low-literacy users, and complaint generation patterns. The fine-tuned adapter genuinely improves Kan's product quality, not just chases the prize. Trainable on free Colab T4 in hours.

### Kan's stacked prize strategy: $80,000 potential

The realistic prize stack Kan targets:

| Prize | Amount | Justification |
|---|---|---|
| Main Track First Prize | $50,000 | Vision, technical execution, real-world impact |
| Digital Equity & Inclusivity | $10,000 | Voice-first, accessible Spanish, Android 8-10 |
| Cactus Prize | $10,000 | Local-first mobile with intelligent model routing |
| Unsloth Prize | $10,000 | Fine-tuned E4B for Guatemalan legal context |
| **Total potential** | **$80,000** | All four are coherent with the product |

The strategy is honest: each prize aligns with a real architectural decision, not a forced fit. If we win the Main Track First we collect $50K; if we win a lower Main Track placement we still collect that plus up to $30K from the other tracks.

### What the hackathon explicitly asks for

The hackathon brief says: *"We want to see how you enhance Gemma 4 models through post-training, domain adaptation, and agentic retrieval to ensure accurate, grounded outputs. Whether you're optimizing E2B and E4B models for edge-based solutions or deploying the 26B and 31B weights for complex tasks, every contribution pushes the boundaries of what AI can achieve."*

This sentence dictates four prominent things to showcase in Kan's submission:

1. **Edge optimization with E4B** (the on-device client running Gemma 4 E4B IT for conversation, OCR, voice).
2. **Server deployment of larger weights** (the Phoenix server using Gemma 4 31B IT Thinking for complex legal reasoning).
3. **Agentic retrieval** (function calling: client tools for sensitive data, server tools for public reasoning).
4. **Post-training / domain adaptation** (Unsloth fine-tuning of E4B on Guatemalan legal corpus — directly aligns with this and unlocks the Unsloth Prize).
5. **Grounded outputs** (the Reasoner cites breach catalog entries, legal templates with legal basis, never hallucinates fiscalía addresses).

### Required submission artifacts

A valid submission must contain all of the following. **All five are mandatory; missing any one disqualifies the entry.**

1. **Kaggle Writeup** — paper or blog-style report explaining the architecture, how Gemma 4 was used specifically, challenges overcome, and why technical choices were correct. Maximum 1,500 words. Submissions over the word limit are subject to penalty. Must select a Track.

2. **Public Video attached to the Media Gallery** — 3 minutes maximum, published to YouTube, viewable without login. The brief calls this *"the most important part of your submission"* and emphasizes storytelling: *"Tell a story. Show us the problem and how your Gemma 4 application solves it in a powerful way."*

3. **Public Code Repository** — GitHub or Kaggle Notebook, well-documented, clearly showing Gemma 4 implementation. *"This is non-negotiable and will be used to validate the authenticity of your project."* No login or paywall. Private Kaggle Notebooks become public after the deadline.

4. **Live Demo** — public URL (or files for download), no login, no paywall.

5. **Media Gallery** with cover image — required to submit the Writeup.

### Binding submission rules (from the official rules document)

These come from the legal rules of the competition. Treat them as binding constraints on how the project is built and submitted.

- **Maximum team size: 5 people.**
- **One submission per team.** For Hackathons, each team is allowed exactly one (1) Submission. Submissions made by individuals before merging into a Team are unsubmitted automatically. **This means: do all development under a single Kaggle account or merge teams correctly before submitting.**
- **Drafts do not count.** Unsubmitted Writeups by the deadline are not considered. Submit early on day 18 with margin.
- **Winning code is licensed CC-BY 4.0.** If Kan wins, the source code is released under CC-BY 4.0 (Open Source Initiative-approved). This means any dependency Kan uses must have a license compatible with redistribution under CC-BY 4.0. AGPL dependencies are **incompatible** and must be avoided. MIT, Apache 2.0, BSD, MPL 2.0, and most permissive licenses are fine. **Verify dependency licenses during development.**
- **Documentation requirements for winners.** Per Section 2.8, winners must deliver: training code, inference code, description of computational environment required, and detailed methodology for reproduction. Plan the README and writeup to satisfy this from day one — do not leave it for the end.
- **External data and tools must satisfy a "Reasonableness Standard."** Public data and tools accessible at minimal cost are allowed. Datasets requiring licenses that exceed the prize amount are not. Google AI Studio (free tier), Cactus (free, open source), Unsloth (free, open source) all pass easily. Verify any other dependencies against this standard.
- **Governing law: California, USA.** Disputes are litigated in Santa Clara County, California. Mention this in the writeup disclaimer.
- **Kaggle and Google employees may participate but cannot win prizes.** Not relevant unless team composition changes.
- **No multiple Kaggle accounts.** One account per person, one entry per team.

### Naming conventions Google requires

Google publishes naming guidelines for Gemma model variants and assets. The implementing LLM must use the exact official names in the writeup, video captions, and code documentation:

- `Gemma 4` for the family (with capital G, space, no hyphen).
- `Gemma 4 E2B` and `Gemma 4 E4B` for edge models.
- `Gemma 4 26B A4B` for the mixture-of-experts mid-tier.
- `Gemma 4 31B IT Thinking` for the top model in instruction-tuned thinking variant.
- Avoid abbreviations like "G4" or "Gemma-4" (with hyphen) in user-facing material.

### What the judges will look for

Inferred from the brief and from prior hackathon winners:

- **Technical rigor** evidenced by the writeup and code repo.
- **The "wow" factor** demonstrated through the video and live demo.
- **Storytelling quality** — the brief literally says: *"Explore the winners and finalists of the Gemma 3n Impact Challenge for examples of submissions that left the judges inspired."*
- **Real-world utility** beyond a tech demo — does this actually help someone?
- **Effective use of Gemma 4-specific capabilities** — function calling, multimodal, edge inference, thinking mode, fine-tuning. Submissions that could have been built with Gemma 3 are at a disadvantage.

### Submission strategy for Kan

Given the requirements above, the production sequence for Kan in the final 18 days prioritizes:

1. Functional working demo first (without polish).
2. Gemma 4 capabilities visibly exercised (function calling logged, thinking mode rendered, multimodal OCR demonstrated, edge inference shown offline in airplane mode, fine-tuned adapter visibly improving responses).
3. Real user case study — recording an actual conversation with a person matching the target user profile, used as primary footage in the video.
4. Live demo URL working publicly without login.
5. Code repo public on GitHub, README pointing at this context document and at the writeup.
6. Writeup written last, structured around the user's story rather than technical architecture (architecture is the "why this works", not the centerpiece).
7. Submit early on day 18 to allow time for fixing technical issues with the Kaggle submission UI itself.

The writeup must explicitly mention the four prize claims (Main Track, Digital Equity, Cactus, Unsloth) so judges can route the submission to all relevant evaluation tracks.

---

## 4. Target user, explicitly

The primary user is a Guatemalan citizen with the following realistic profile, encoded by the case of "Petén April 2026" where 70 women in aldea Caoba, Flores, Petén were victims of identity theft after handing over their DPIs and photos in exchange for groceries to a fake NGO:

- **Device:** Android 8 to 10, 4 to 6 GB RAM, 64 GB storage, often shared family device.
- **Connectivity:** intermittent 3G/4G in rural areas, sometimes only WiFi at home.
- **Digital literacy:** comfortable with WhatsApp and YouTube, not with forms or settings menus.
- **Language:** Spanish only for this version. Mayan language support deferred — corpora and validation for q'eqchi', k'iche', mam, kaqchikel are insufficient for honest delivery in 18 days.
- **Trust model:** distrusts government but trusts community and family. Will believe a friend over a website.
- **Threat actors:** social engineers (fake NGOs, fake bank calls), corrupt insiders at banks who open accounts with mismatched photos, organized scams that monetize stolen DPIs.

The interface must be optimized for this user. **Voice-first**. Buttons exist as fallback only. Text on screen must be large, simple, with no jargon.

---

## 5. The problem in concrete numbers

Real Guatemalan breaches the app must address (with publication dates):

- **Mintrab "Tu Empleo" (April 2026):** DPI numbers, addresses, phone numbers, CVs of users registered after the 2026 National Employment Fair. Database for sale on dark web. Root cause stated by Mintrab: outdated API code with no access controls.
- **Digecam (April 2026):** weapons-permit holder data. Institution claims data "is not at risk" despite confirmed breach.
- **Hackers demanding Q1.2 million** to stop ongoing attacks against multiple institutions (Prensa Libre report, April 2026).
- **USAC and Universidad Rafael Landívar** acknowledged compromise.
- **Cancillería 2022:** Chinese-origin actors infiltrated. Detected by US Southern Command, not Guatemala itself.
- **Structural finding:** of 134 government platforms studied by VECERT, security practices are not generally applied. Digecam scored 41/100.

Kan operates in the world these breaches created, where millions of citizens have their data already public and don't know it.

---

## 6. The three core flows

### Flow A — User discovered they were victim
User: *"Vino una fiscal que dice que abrieron una cuenta a mi nombre."*
Kan: greets, asks key questions (DPI physically stolen vs only data, when they realized, what evidence they have).
Kan: runs local breach verification, explains findings.
Kan: generates filled denuncia for Ministerio Público with the user's specific facts.
Kan: tells them the nearest fiscalía address, hours, what documents to bring.
Kan: offers to print, save as PDF, or send via WhatsApp to a family member.

### Flow B — User suspects but not sure
User: *"Recibí una llamada rara, dijeron que era de un banco."*
Kan: asks what was requested.
Kan: explains red flags clearly (legitimate banks don't ask for DPI by phone).
Kan: if user gave info → enter Flow A. If not → preventive verification + scam awareness.

### Flow C — Preventive verification
User: *"Quiero saber si mis datos están en internet."*
Kan: explains the verification works locally, asks for CUI.
Kan: shows clear result with sources cited, explains what each breach means.
Kan: offers preventive steps (block credit bureau queries, alert bank, set monthly check reminder).

---

## 7. Architecture: split-tier inference with privacy preservation

The key architectural principle is **split-tier inference**:

- **All raw personal data stays on the client device.** DPI numbers, names, addresses, phone numbers, photos of identity documents, audio of the user's voice — none of this ever leaves the phone in cleartext.
- **The server processes only abstract case descriptions** that contain no identifiers. The client extracts the structure of a situation ("person in Petén department reporting bank-account fraud with stolen DPI, no prior MP contact") and sends that to the server. The server returns reasoning and templates. The client fills personal data into templates locally.

This means the server **cannot** leak personal data even if it is fully compromised, because it never had any. This is the strongest possible privacy guarantee short of fully on-device processing, while still benefiting from a more capable server-side model for legal reasoning.

### Component map

```
┌─────────────────────────────────────────┐
│  Flutter mobile app (Android, iOS)      │
│                                         │
│  - Gemma 4 E4B IT (default, fast)       │
│  - Gemma 4 E4B IT Thinking (complex)    │
│  - Local SQLite of breach hash index    │
│  - Local document templates             │
│  - Local PDF rendering                  │
│  - Native TTS (Android TextToSpeech)    │
│                                         │
│  All sensitive data stays here.         │
└────────────┬────────────────────────────┘
             │ HTTPS (TLS 1.3)
             │ Phoenix Channels (WebSocket) for streaming
             │ Only abstract descriptions, no PII
             ▼
┌─────────────────────────────────────────┐
│  Phoenix server (Elixir)                │
│                                         │
│  - Gemma 4 31B IT Thinking via          │
│    Google AI Studio (Gemini API)        │
│  - Public breach hash distribution      │
│  - Legal procedure catalog              │
│  - Anonymous metrics aggregation        │
│  - LiveView panel at kan.gt             │
│                                         │
│  Has no PII. Cannot leak what it never  │
│  had.                                   │
└─────────────────────────────────────────┘
```

### Why each technology

**Flutter** for the client. Single codebase for Android and iOS. Reasonable binary size on Android 8-10. **Cactus SDK** (cactus-compute, Y Combinator-backed) is the chosen on-device inference engine, not `flutter_gemma`. Three reasons:

1. **Cactus is what the Cactus Prize ($10K) describes.** The prize text — *"local-first mobile or wearable application that intelligently routes tasks between models"* — describes Cactus literally. Kan's split-tier architecture (E4B on device, 31B on server) is exactly what Cactus's hybrid routing is built for.
2. **Day-one Gemma 4 support.** Cactus shipped pre-quantized Gemma 4 weights (E2B, E4B, both at INT4/INT8/FP16) the day Gemma 4 launched. Audio handled natively (eliminates Whisper.cpp from the client). Vision native (eliminates separate OCR libraries).
3. **Cloud handoff built in.** Cactus's confidence-based routing means the client itself decides whether the local E4B can handle a task or whether to escalate to the server (Phoenix + Google AI Studio + Gemma 4 31B). Kan's split-tier inference is implemented partly by Cactus's existing routing primitives, partly by Kan's own logic for which case types always require server reasoning.

Cactus is open source, free for non-profits, free tier permanent. Available in Flutter, Kotlin, and React Native — Kan uses the Flutter SDK.

**Unsloth** for fine-tuning Gemma 4 E4B on Kan's specific domain. The fine-tuned adapter (LoRA, ~50MB) is bundled with the app. It produces noticeably better answers in three areas:

1. **Guatemalan legal vocabulary.** Generic Gemma 4 knows "denuncia" but does not know the specific structure of denuncias before the Ministerio Público de Guatemala, the difference between PDH and MP procedures, or the specific articles of the Código Procesal Penal that apply to identity theft cases.
2. **Accessible Spanish for low-literacy users.** Tone calibration: shorter sentences, simpler vocabulary, no legal jargon when explaining to the user, jargon only where it appears in the generated documents.
3. **Conversation patterns specific to the three flows** (victim, suspicion, prevention). Few-shot examples baked into the model rather than provided at runtime, reducing prompt size and improving consistency.

**Training cost:** Gemma 4 E4B with QLoRA fits in a free Google Colab T4 GPU (~10GB VRAM). Training time: ~1-3 hours per epoch on a curated dataset of 500-1000 examples. **Total realistic training cost for the hackathon: zero dollars** (free Colab). The dataset is the work, not the compute.

**Dataset construction:** the implementing team builds a JSONL dataset of (prompt, expected response) pairs covering the three flows. Sources include: real Guatemalan legal templates (with PII redacted), simulated conversations with the target user persona, examples of accessible Spanish from existing PDH educational materials. Aim for ~75% of examples with reasoning preserved (matching Unsloth's recommendation to maintain Gemma 4's thinking capability).

**Output:** a LoRA adapter exported in GGUF format for consumption by Cactus on device. The base Gemma 4 E4B IT weights stay unmodified; the adapter is loaded on top at runtime.

**Why this is real and not just for the prize:** without fine-tuning, generic Gemma 4 E4B produces denuncias that mention non-existent Guatemalan laws or use Spanish that is too formal for the target user. With fine-tuning on a curated legal corpus, the outputs become legally accurate and tonally appropriate. **The prize and the product quality both pull in the same direction.**

**Gemma 4 E4B IT** as default on the client. Runs offline after initial download. Has native audio support (no separate Whisper.cpp needed if benchmark confirms acceptable latency on target devices) and native vision support (no separate OCR library needed for DPI reading). Native function calling for invoking local tools.

**Gemma 4 E4B IT Thinking** for complex client-side cases. Same model, thinking mode active. Slower but produces better-reasoned answers for legally consequential decisions.

**Gemma 4 31B IT Thinking** on the server, accessed via **Google AI Studio** (Gemini API). The 31B IT Thinking is the top model in the Gemma 4 family: 1452 Arena AI score, 89.2% on AIME 2026, 86.4% on τ2-bench Retail (agentic tool use), 80.0% on LiveCodeBench v6. The agentic tool use score is the critical one for Kan: vs 6.6% on Gemma 3 27B, the jump is what makes Kan a real agent rather than a chatbot. Hosted by Google means no local GPU is required and no third-party aggregator sits in the path. The choice of 31B over 26B A4B is deliberate for the hackathon: marginal improvements in benchmark scores translate to noticeably better demo quality, which is what judges see.

**Why not Gemini API:** sovereign control, predictable cost, offline-capable client, alignment with hackathon goal of using Gemma 4 specifically. Not an alternative for the client at all (Gemma 4 E4B is the only realistic on-device option in 2026).

**Elixir + Phoenix + LiveView** for the server. Three reasons:
1. BEAM actor model: each user conversation is an isolated process. Crashes don't cascade.
2. LiveView gives real-time UI updates without writing JavaScript. The public panel at `kan.gt` shows live national metrics, anonymous, animated — this is the centerpiece of the demo video.
3. Phoenix Channels: WebSocket-based streaming for token-by-token model output. Keeps the user engaged during 5-15 second model latency.

**Google AI Studio (Gemini API)** for serving Gemma 4 31B IT Thinking on the server side. This is **Google's official platform for Gemma**, and using it is a deliberate choice for the hackathon:

- **It is the path Google recommends.** The official Gemma 4 page at deepmind.google links directly to Google AI Studio with the model `gemma-4-31b-it` pre-selected. The judges of the Gemma 4 Good Hackathon are aligned with Google. When two technically comparable submissions are evaluated, the one using Google's recommended path has a narrative advantage that costs nothing to capture.
- **Free tier is generous.** For hackathon volumes (development testing across 18 days plus the demo), Gemma models in Google AI Studio fit comfortably in the free tier. No credit card friction, no surprise bills.
- **Native function calling and streaming.** Both required by Kan's agentic flow. Google's SDK supports them natively without workarounds.
- **Single SDK, single auth, one dependency.** The official `google-ai-generativelanguage` library (Python) or any Gemini-compatible client (Elixir HTTP, Go SDK) works directly. No aggregator layer that might add latency or change behavior between providers.
- **Direct alignment with multimodal capabilities.** When the client uses Gemma 4 vision for OCR of the DPI, the server-side reasoning uses the same model family from the same vendor. This is consistent and easy to reason about.

**Important constraint for now:** Google AI Studio only. No Ollama, no OpenRouter, no Together AI, no aggregators. The reason is alignment with the hackathon and operational simplicity in 18 days. After the hackathon, when there is a stable user base and predictable token volumes, the decision can be revisited — at that point, self-hosting Gemma 4 on a dedicated GPU droplet, or migrating to Vertex AI for higher-volume production, are valid options. The Phoenix `Kan.Reasoner` module is built to be backend-agnostic so the swap is configuration-only.

**Caddy** as reverse proxy. Automatic TLS, HTTP/3 native, written in Go (memory-safe), 3-line configuration. Sits between Cloudflare (optional edge) and the Phoenix server.

**PostgreSQL 18** for the small amount of relational data: breach catalog, fiscalía directory, anonymous metrics. PostgreSQL 18 (released September 25, 2025) brings several features that directly benefit Kan:

- **Native `uuidv7()` function.** No more app-side UUID generation, no `pg_uuidv7` extension, no `gen_random_uuid()` (UUIDv4) fragmentation. Just `DEFAULT uuidv7()` in column definitions. PostgreSQL 18 also adds `uuidv4()` as an alias for `gen_random_uuid()` for naming consistency.
- **Asynchronous I/O (AIO) subsystem.** Up to 3x performance gains on read-heavy workloads. The breach hash lookups, the fiscalía directory queries, and the metrics aggregations are all read-heavy. AIO is enabled by default with `io_method = worker`. On Linux 5.1+ servers, switching to `io_method = io_uring` provides additional gains.
- **Skip scan on multi-column B-tree indexes.** Queries that filter on the second column of a composite index (e.g., `WHERE department_code = 17 AND occurred_at > now() - INTERVAL '1 day'` on `idx_metrics(department_code, occurred_at)`) now use the index efficiently without manual index gymnastics.
- **`OLD` and `NEW` in `RETURNING` clauses.** Audit-friendly: a single `UPDATE ... RETURNING old.*, new.*` captures before/after values without a separate `SELECT` query. Useful for the anonymous metrics tables when fields are updated.
- **Temporal constraints with `WITHOUT OVERLAPS` and `PERIOD`.** Native support for ranges in PRIMARY KEY, UNIQUE, FOREIGN KEY constraints. Not used in Kan v1, but reserved for future Bacab credential validity periods that should not overlap.
- **OAuth 2.0 authentication to the database.** Permits integration with corporate SSO providers without managing local Postgres roles. Useful when Kan is operated by an institution with existing identity infrastructure.
- **Faster `pg_upgrade`.** New `--swap` option exchanges data directories instead of copying. Statistics preservation across major version upgrades, eliminating the post-upgrade performance valley.

The minimum supported version for Kan is **PostgreSQL 18**. Older versions are not supported. If a deployment environment has only PostgreSQL 16 or 17 available, the deployment is blocked until 18 is provisioned. The reason: Kan depends on `uuidv7()` natively, and falling back to app-side generation introduces inconsistencies across services that share the same database.

**OpenTofu** for infrastructure as code. Fork of Terraform under Linux Foundation. Module-compatible with Terraform.

**DigitalOcean** for hosting initially. Specifically: one Droplet for Phoenix + Caddy + PostgreSQL 18, one DigitalOcean Spaces bucket for static assets and backups. **No GPU droplet needed** because all LLM inference runs on Google AI Studio as a hosted API.

---

## 8. Tech stack summary table

| Layer | Tool | Purpose |
|---|---|---|
| Client framework | Flutter (Dart) | Android + iOS single codebase |
| On-device inference engine | Cactus SDK | Local-first inference + intelligent cloud routing (Cactus Prize target) |
| Client LLM | Gemma 4 E4B IT (base + Unsloth LoRA adapter) | Conversational, multimodal, function calling, all on-device |
| Fine-tuning | Unsloth on Google Colab T4 | LoRA adapter for Guatemalan legal context (Unsloth Prize target) |
| Client TTS | Native Android TextToSpeech | Voice output without bundling models |
| Client storage | SQLite via sqflite | Breach hashes, templates, conversation history |
| Server language | Elixir | Concurrent, fault-tolerant, real-time |
| Server framework | Phoenix + LiveView | HTTP, WebSocket, real-time UI |
| Server LLM | Gemma 4 31B IT Thinking | Agentic reasoning, legal templates, abstract analysis |
| LLM serving | Google AI Studio (Gemini API) | Hosted Gemma 4 31B IT Thinking, Google's official path |
| Database | PostgreSQL 18 with native uuidv7() | Relational, no graph, no fragmentation, AIO performance |
| Reverse proxy | Caddy | Auto-TLS, HTTP/3, simple config |
| Edge (optional) | Cloudflare | DDoS, WAF, global cache |
| Background jobs | Oban (Elixir) | Periodic breach catalog updates, metrics rollup |
| Pub/Sub | Phoenix.PubSub | Internal events for LiveView updates |
| Observability | OpenTelemetry → Grafana Cloud | Logs, metrics, traces |
| Infra as code | OpenTofu | Reproducible deployment |
| Containerization | Docker + distroless images | Minimal attack surface |
| Hosting | DigitalOcean Droplets | Affordable, portable, S3-compatible storage |
| LLM inference | Google AI Studio (hosted Gemma 4 31B) | Google's official platform, free tier, no GPU operation |
| CI/CD | GitHub Actions | Standard, free for public repos |

---

## 9. Project structure

### Server repo: `kan-server`

```
kan-server/
├── README.md
├── INFRA.md                         # full infrastructure guide
├── Dockerfile
├── docker-compose.yml               # local dev only
├── Makefile
├── mix.exs
├── mix.lock
├── config/
│   ├── config.exs
│   ├── dev.exs
│   ├── prod.exs
│   └── runtime.exs
├── lib/
│   ├── kan/
│   │   ├── application.ex
│   │   ├── reasoner.ex              # Gemma 4 31B inference client
│   │   ├── breach_catalog.ex        # public breach data management
│   │   ├── legal_templates.ex       # template catalog
│   │   ├── fiscalias.ex             # prosecutor office directory
│   │   ├── metrics.ex               # anonymous metrics
│   │   ├── tools/                   # function-calling tools for Gemma
│   │   │   ├── search_breaches.ex
│   │   │   ├── get_legal_procedure.ex
│   │   │   ├── get_template.ex
│   │   │   └── nearest_fiscalia.ex
│   │   ├── repo.ex                  # Ecto repository
│   │   └── pubsub.ex                # Phoenix.PubSub setup
│   ├── kan_web/
│   │   ├── endpoint.ex
│   │   ├── router.ex
│   │   ├── controllers/
│   │   │   ├── breach_controller.ex     # GET /api/breaches/index (signed)
│   │   │   ├── template_controller.ex   # GET /api/templates/{id}
│   │   │   └── reason_controller.ex     # POST /api/reason (server-side reasoning)
│   │   ├── channels/
│   │   │   └── reason_channel.ex        # WebSocket for streaming reasoning
│   │   ├── live/
│   │   │   ├── transparency_live.ex     # public dashboard at kan.gt
│   │   │   └── components/
│   │   └── components/
│   │       └── core_components.ex
├── priv/
│   ├── repo/
│   │   └── migrations/
│   │       ├── 20260501000001_create_breaches.exs
│   │       ├── 20260501000002_create_fiscalias.exs
│   │       ├── 20260501000003_create_templates.exs
│   │       └── 20260501000004_create_anonymous_metrics.exs
│   └── static/
├── test/
└── infra/
    ├── modules/
    │   ├── network/
    │   ├── compute/
    │   ├── database/
    │   ├── storage/
    │   ├── inference_gpu/
    │   └── observability/
    └── environments/
        ├── dev/
        └── prod/
```

### Client repo: `kan-app`

```
kan-app/
├── README.md
├── pubspec.yaml
├── android/
├── ios/
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── core/
│   │   ├── theme.dart
│   │   ├── routes.dart
│   │   └── services/
│   │       ├── cactus_service.dart           # wrapper over Cactus SDK + Unsloth adapter
│   │       ├── audio_service.dart            # mic input, TTS output
│   │       ├── breach_verifier.dart          # local hash lookup
│   │       ├── pdf_generator.dart            # local PDF rendering
│   │       ├── server_client.dart            # HTTP + Phoenix Channels
│   │       └── storage_service.dart          # SQLite operations
│   ├── features/
│   │   ├── conversation/
│   │   │   ├── conversation_screen.dart
│   │   │   ├── conversation_controller.dart
│   │   │   └── widgets/
│   │   │       ├── voice_visualizer.dart
│   │   │       ├── thinking_indicator.dart
│   │   │       └── transcript_view.dart
│   │   ├── verification/
│   │   │   ├── verification_screen.dart
│   │   │   └── verification_result.dart
│   │   ├── document_generation/
│   │   │   ├── document_preview.dart
│   │   │   └── document_actions.dart
│   │   ├── dpi_scanner/
│   │   │   └── dpi_scanner_screen.dart       # camera + Gemma vision
│   │   └── onboarding/
│   │       └── onboarding_flow.dart
│   ├── tools/                                # function-calling local tools
│   │   ├── verify_dpi_in_local_leaks.dart
│   │   ├── extract_dpi_from_image.dart
│   │   ├── fill_legal_template.dart
│   │   └── find_nearest_fiscalia.dart
│   └── models/
│       ├── breach.dart
│       ├── conversation_event.dart
│       └── legal_template.dart
├── assets/
│   ├── models/
│   │   ├── gemma-4-e4b-it.cact               # Cactus format weights, downloaded on first run
│   │   └── kan-legal-es-gt.lora              # Unsloth LoRA adapter, ~50MB, bundled in APK
│   ├── templates/
│   │   ├── denuncia_mp.txt
│   │   ├── queja_pdh.txt
│   │   └── solicitud_bloqueo_buro.txt
│   └── breach_hashes.db                      # initial bundled, updated via sync
├── fine_tuning/                               # Unsloth LoRA training (Unsloth Prize)
│   ├── README.md                              # how to reproduce the training
│   ├── dataset/
│   │   ├── flow_a_victim_examples.jsonl       # ~200 examples
│   │   ├── flow_b_suspicion_examples.jsonl    # ~200 examples
│   │   ├── flow_c_prevention_examples.jsonl   # ~150 examples
│   │   ├── legal_template_filling.jsonl       # ~300 examples
│   │   └── accessible_spanish_tone.jsonl      # ~150 examples
│   ├── notebook/
│   │   └── train_kan_lora.ipynb               # runs on free Colab T4
│   ├── benchmarks/
│   │   ├── before_after_comparison.md         # quality before/after fine-tuning
│   │   └── kl_divergence_results.md
│   └── exports/
│       └── kan-legal-es-gt.lora               # output adapter, copied to assets/models/
└── test/
```

---

## 10. Data model

### Public breach catalog (server-side)

```sql
-- Requires PostgreSQL 18+
CREATE TABLE breaches (
  id UUID PRIMARY KEY DEFAULT uuidv7(),        -- Native PG 18 UUIDv7
  slug TEXT UNIQUE NOT NULL,                   -- 'mintrab-tu-empleo-2026-04'
  display_name TEXT NOT NULL,                  -- 'Filtración Mintrab Tu Empleo'
  institution TEXT NOT NULL,                   -- 'Ministerio de Trabajo'
  occurred_on DATE NOT NULL,
  disclosed_on DATE NOT NULL,
  data_types TEXT[] NOT NULL,                  -- ['dpi', 'name', 'address', 'phone', 'cv']
  estimated_records BIGINT,
  source_urls TEXT[] NOT NULL,                 -- news articles, official statements
  description_es TEXT NOT NULL,                -- plain Spanish description
  recommended_actions TEXT[] NOT NULL,
  hash_index_url TEXT NOT NULL,                -- where to download SHA-256 hash list
  hash_index_signature BYTEA NOT NULL,         -- Ed25519 signature of hash list
  status TEXT NOT NULL DEFAULT 'active',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_breaches_disclosed ON breaches(disclosed_on DESC);
```

### Fiscalía directory

```sql
CREATE TABLE fiscalias (
  id UUID PRIMARY KEY DEFAULT uuidv7(),
  name TEXT NOT NULL,
  jurisdiction TEXT NOT NULL,                  -- 'Petén/Flores', 'Guatemala/Zona 1'
  department_code SMALLINT NOT NULL,
  municipality_code SMALLINT,
  address TEXT NOT NULL,
  phone TEXT,
  hours TEXT,
  cybercrime_specialized BOOLEAN NOT NULL DEFAULT FALSE,
  latitude DECIMAL(9,6),
  longitude DECIMAL(9,6),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Skip scan in PG 18 makes this composite index efficient even when
-- queries filter only on the second column (cybercrime_specialized).
CREATE INDEX idx_fiscalias_dept ON fiscalias(department_code, cybercrime_specialized);
```

### Legal templates

```sql
CREATE TABLE legal_templates (
  id UUID PRIMARY KEY DEFAULT uuidv7(),
  slug TEXT UNIQUE NOT NULL,                   -- 'denuncia_mp_suplantacion_dpi'
  display_name TEXT NOT NULL,
  applies_to TEXT[] NOT NULL,                  -- case types
  jurisdiction_code TEXT,                      -- nullable means national
  template_text TEXT NOT NULL,                 -- with {{placeholders}}
  required_fields JSONB NOT NULL,              -- field names + types
  legal_basis TEXT NOT NULL,                   -- citations
  version INTEGER NOT NULL DEFAULT 1,
  effective_from DATE NOT NULL,
  signed_by_legal_advisor TEXT NOT NULL,
  signature BYTEA NOT NULL,                    -- so client can verify authenticity
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

### Anonymous metrics (no PII)

```sql
CREATE TABLE anonymous_metrics (
  id UUID PRIMARY KEY DEFAULT uuidv7(),
  occurred_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  event_type TEXT NOT NULL,                    -- 'check_completed', 'denuncia_generated'
  department_code SMALLINT,                    -- coarse, not GPS
  case_type TEXT,
  outcome TEXT,
  app_version TEXT
);

-- The id column itself is timestamp-ordered (UUIDv7), so an ORDER BY id DESC
-- gives chronological order for free without needing occurred_at, but we
-- keep occurred_at explicit for clarity and for queries that span days.
CREATE INDEX idx_metrics_time ON anonymous_metrics(occurred_at DESC);

-- Composite index leveraging PG 18's skip scan: queries that filter only
-- on event_type still benefit from this index without a separate one.
CREATE INDEX idx_metrics_dept_type ON anonymous_metrics(department_code, event_type, occurred_at DESC);
```

### Client-side SQLite (on device)

SQLite does not have native UUIDv7 support. The client generates UUIDv7 in Dart using a package like `uuid: ^4.x` which supports v7, then inserts as TEXT. The pattern is consistent with the server-side generation but the implementation differs.

```sql
-- Conversation history (only on this device)
CREATE TABLE conversations (
  id TEXT PRIMARY KEY,                         -- UUIDv7 generated in Dart
  started_at INTEGER NOT NULL,                 -- unix ms
  ended_at INTEGER,
  case_type TEXT,
  status TEXT NOT NULL                         -- 'active', 'completed', 'abandoned'
);

CREATE TABLE conversation_turns (
  id TEXT PRIMARY KEY,                         -- UUIDv7 generated in Dart
  conversation_id TEXT NOT NULL REFERENCES conversations(id),
  role TEXT NOT NULL,                          -- 'user', 'assistant'
  content TEXT NOT NULL,
  audio_path TEXT,                             -- if voice turn
  occurred_at INTEGER NOT NULL
);

-- Breach hash index (downloaded from server, signed by Ed25519 public key)
CREATE TABLE breach_hashes (
  hash TEXT PRIMARY KEY,                       -- SHA-256 of (DPI || public_salt)
  breach_slug TEXT NOT NULL,
  added_at INTEGER NOT NULL
);

CREATE INDEX idx_breach_hashes_slug ON breach_hashes(breach_slug);

-- User preferences
CREATE TABLE preferences (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL
);
```

**Dart UUIDv7 generation example** (for the implementing LLM to follow):

```dart
import 'package:uuid/uuid.dart';

final uuid = Uuid();
final id = uuid.v7();  // returns timestamp-ordered UUIDv7 string
```

---

## 11. Function-calling tools

Gemma 4's native function calling is the core capability that makes Kan an agent rather than a chatbot. Tools are split between client and server based on data sensitivity.

### Client-side tools (sensitive data)

```
verify_dpi_in_local_leaks(dpi: string) -> {
  found: boolean,
  matches: [{breach_slug: string, breach_name: string, disclosed_on: string}]
}

extract_dpi_from_image(image_path: string) -> {
  cui: string,
  full_name: string,
  birth_date: string,
  confidence: float
}

fill_legal_template(template_slug: string, fields: object) -> {
  pdf_path: string,
  text_content: string
}

find_nearest_fiscalia(department_code: integer, cybercrime: boolean) -> {
  name: string,
  address: string,
  phone: string,
  hours: string,
  distance_km: float
}

schedule_followup_reminder(date: string, what: string) -> {
  reminder_id: string
}

share_via_whatsapp(file_path: string, message: string) -> {
  status: 'sent' | 'cancelled'
}
```

### Server-side tools (public data, agentic)

```
search_known_breaches(case_signature: string) -> [
  {breach_slug, institution, occurred_on, data_types, description}
]

get_legal_procedure_for_case(case_type: string, jurisdiction: string) -> {
  steps: [{order, action, requirements, estimated_time}],
  applicable_laws: [{name, articles}]
}

get_template_for_jurisdiction(template_slug: string, dept_code: integer) -> {
  template_text: string,
  required_fields: object,
  legal_basis: string
}

cross_reference_recent_news(institution: string, since: string) -> [
  {url, title, published_at, summary}
]

report_anonymous_metric(metric_type: string, dept_code: integer, case_type: string) -> {
  acknowledged: boolean
}
```

### Tool invocation flow

1. User speaks to client: *"creo que me robaron los datos"*
2. Gemma 4 E4B (client) thinks, then calls `verify_dpi_in_local_leaks(dpi)`.
3. Tool executes locally, returns matches.
4. Client decides if server reasoning is needed. If case is non-trivial, client constructs **abstract case description** (no PII) and sends to server via Phoenix Channel.
5. Server's Gemma 4 31B Thinking receives abstract case, may call `get_legal_procedure_for_case`, `get_template_for_jurisdiction`, etc.
6. Server streams reasoning + final response back to client token by token.
7. Client receives template, calls local `fill_legal_template(slug, personal_data)` to fill it, then `share_via_whatsapp` or print.

The server **never sees** the DPI, name, address, or phone. It sees something like: `{case_type: "identity_theft", channel: "data_only", department: 17, time_since_incident: "6_months", evidence_available: ["bank_statement", "fiscalia_summons"]}`.

---

## 12. Real-time UX with Phoenix LiveView and Channels

### LiveView for the public transparency panel at kan.gt

The home page is a LiveView that updates in real time using Phoenix.PubSub. Visitors see:

- A live counter of verifications performed today (no PII).
- A heatmap of Guatemala showing which departments have more alerts today.
- A feed of the most recent confirmed breaches, with sources.
- An anonymous live event ticker: "Una persona en Sololá completó una denuncia hace 2 minutos."

When any client reports a metric (anonymized), it is broadcast on PubSub topic `metrics:updates`. Every connected LiveView receives the event and re-renders the affected component. No JavaScript written by hand. No manual WebSocket plumbing.

Pseudocode of the LiveView shape:

```
defmodule KanWeb.TransparencyLive do
  use KanWeb, :live_view
  
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Kan.PubSub, "metrics:updates")
    end
    {:ok, socket
      |> assign(:total_checks_today, Metrics.checks_today())
      |> assign(:positives_today, Metrics.positives_today())
      |> assign(:by_department, Metrics.by_department())
      |> assign(:recent_breaches, BreachCatalog.recent(limit: 5))
      |> stream(:event_feed, Metrics.recent_events(limit: 10))}
  end
  
  def handle_info({:metric, event}, socket) do
    socket = update_counters(socket, event)
    {:noreply, stream_insert(socket, :event_feed, event, at: 0, limit: 10)}
  end
  
  def render(assigns), do: ...
end
```

### Phoenix Channels for streaming reasoning

When the client needs server reasoning, it joins a per-conversation channel. The server invokes Gemma 4 31B with streaming and pushes each token to the channel as it is produced. The client speaks each chunk via TTS as it arrives, creating the impression of natural conversation rather than waiting in silence.

```
defmodule KanWeb.ReasonChannel do
  use KanWeb, :channel
  
  def join("reason:" <> conversation_id, _params, socket) do
    {:ok, assign(socket, :conversation_id, conversation_id)}
  end
  
  def handle_in("reason", %{"case" => abstract_case}, socket) do
    Task.start(fn ->
      Kan.Reasoner.stream(abstract_case, fn token ->
        push(socket, "token", %{text: token})
      end, fn final ->
        push(socket, "complete", %{response: final})
      end)
    end)
    {:reply, :ok, socket}
  end
end
```

### Thinking mode visualization

When Gemma 4 31B Thinking is generating reasoning, the client shows an animated indicator with the actual reasoning text streaming (in a smaller, lighter style) before the final answer. This is both transparency (user can see the model's logic) and compelling video material for the hackathon submission.

---

## 13. Privacy and security commitments

These are non-negotiable. The LLM implementing Kan must refuse or flag any code that violates them.

1. **DPI numbers, names, addresses, phone numbers, photos of identity documents, voice audio: never leave the client device in cleartext.**
2. **Server logs may contain timestamps, departments at coarse level, case types, app versions. Server logs must never contain identifiers, even hashed, even tokenized.**
3. **TLS 1.3 minimum** for all network communication, with hybrid post-quantum suite `X25519MLKEM768` when supported by edge.
4. **All outbound HTTP calls from the client to the server use certificate pinning**.
5. **The server's signed breach hash index** is verified by the client using a public key bundled in the app, before it is trusted.
6. **The legal templates** are signed by a designated legal advisor. Client verifies signature before generating documents.
7. **Voice audio is processed on-device by Gemma 4 E4B** (or fallback Whisper.cpp). It is never uploaded.
8. **Camera images of DPIs are processed on-device by Gemma 4 E4B vision**. Never uploaded.
9. **Anonymous metrics:** the only fields permitted are `event_type`, `department_code` (1-22), `case_type` (enum), `app_version`, `timestamp`. Anything else is a privacy regression and must be rejected in code review.
10. **Conversation history on device** is encrypted at rest using a key in the Android Keystore (or iOS Keychain). Lost device → unrecoverable history.

---

## 14. PostgreSQL 18 tuning for Kan

PostgreSQL 18 ships with sane defaults, but Kan benefits from specific tuning that takes advantage of the new capabilities. The configuration below is for the production Droplet (8 GB RAM, NVMe SSD).

### `postgresql.conf` adjustments

```conf
# Asynchronous I/O — the headline feature of PG 18
io_method = io_uring                # Linux 5.1+ only; falls back to 'worker' if unavailable
io_combine_limit = 256kB            # default 128kB; raises to combine more reads
io_max_combine_limit = 1MB          # cap on combined I/O size

# These now matter even on systems without fadvise() because of AIO
effective_io_concurrency = 16       # for SSD/NVMe; tune higher for striped storage
maintenance_io_concurrency = 16

# Memory tuning for an 8 GB instance dedicated mostly to PG
shared_buffers = 2GB                # 25% of RAM for dedicated PG box
effective_cache_size = 6GB          # PG's estimate of OS cache; ~75% of RAM
work_mem = 32MB                     # per-operation; sized for typical aggregations
maintenance_work_mem = 512MB        # for VACUUM, CREATE INDEX, etc.

# Logging
log_min_duration_statement = 1000   # log queries slower than 1s
log_lock_waits = on
log_temp_files = 0                  # log all temp file creation (size 0 means all)

# WAL
wal_compression = lz4               # default; cheap CPU for big network savings
max_wal_size = 4GB
min_wal_size = 1GB

# Statistics
default_statistics_target = 100
```

### Why these values matter for Kan

- `io_method = io_uring` is a single-line change that delivers up to 3x improvement on cold reads. For Kan, breach hash lookups when a new breach is added (cold cache) and analytics queries on the metrics table both benefit directly.
- `effective_io_concurrency = 16` previously did nothing on systems without `fadvise()`. With PG 18 AIO, it now controls how many I/O requests the database keeps in flight simultaneously. NVMe SSDs handle 16 concurrent reads easily.
- `wal_compression = lz4` was added in PG 15 but the default changed. Confirm it is enabled because Kan replicates WAL across regions in production and bandwidth matters.

### Kan-specific maintenance jobs

Run via Oban (Elixir) on the Phoenix server, scheduled with cron-like syntax:

| Job | Frequency | Purpose |
|---|---|---|
| `VACUUM ANALYZE` on hot tables | Daily 04:00 UTC | Reclaim space, update statistics |
| `REINDEX CONCURRENTLY` on metrics table | Weekly Sunday 04:00 | Refresh indexes for the most-written table |
| Breach catalog ingestion | Hourly | Pull new breaches from sources, sign hash index |
| Anonymous metrics rollup | Daily 03:00 UTC | Pre-aggregate daily counts for the LiveView panel |
| Backup (pg_dump) | Daily 02:00 UTC | Encrypted dump uploaded to Spaces |
| Backup verification | Weekly Sunday 06:00 | Test restore in staging environment |

### Migration policy

Migrations live in `priv/repo/migrations/` (Elixir Ecto convention). Naming format: `YYYYMMDDHHMMSS_description.exs`. Forward migrations are required; down migrations are optional in development, prohibited from being relied upon in production. Production rollback strategy is restore from backup, not down-migrate.

The first migration (`20260501000000_enable_extensions.exs`) ensures that PostgreSQL is at least version 18:

```elixir
defmodule Kan.Repo.Migrations.EnableExtensions do
  use Ecto.Migration

  def change do
    # Enforce PostgreSQL 18+ at migration time
    execute """
    DO $$
    BEGIN
      IF current_setting('server_version_num')::int < 180000 THEN
        RAISE EXCEPTION 'Kan requires PostgreSQL 18 or later. Current version: %',
          current_setting('server_version');
      END IF;
    END $$;
    """, "SELECT 1"

    # No CREATE EXTENSION needed for uuidv7() — it is built-in in PG 18.
    # We only enable extensions that are not part of core.
    execute "CREATE EXTENSION IF NOT EXISTS pg_trgm", "DROP EXTENSION pg_trgm"
    execute "CREATE EXTENSION IF NOT EXISTS pgcrypto", "DROP EXTENSION pgcrypto"
  end
end
```

`pg_trgm` is included for fuzzy-matching of fiscalía names (the user might say "fiscalía de Petén" instead of the exact registered name). `pgcrypto` is included for hash digest functions used in anonymous metrics rollups.

---

## 15. Deployment topology

For hackathon demo:

- **Cloudflare** (free tier) at `kan.gt` and `api.kan.gt` for edge TLS, DDoS, cache.
- **Caddy** on a single DigitalOcean Droplet (2 vCPU, 4 GB RAM, NYC3) as reverse proxy. Auto-TLS via Let's Encrypt.
- **Phoenix server** on the same Droplet via Docker. Connected to Postgres on the same Droplet (acceptable for hackathon scale; would be separated for production).
- **Gemma 4 31B IT Thinking served via Google AI Studio (Gemini API)** as hosted endpoint. Phoenix calls it over HTTPS using a single API key stored as an environment variable. No GPU to provision, no inference server to maintain, no aggregator layer in between. This is the path Google recommends and what aligns with the hackathon evaluation.
- **Static assets and breach hash files** in DigitalOcean Spaces (S3-compatible).
- **Public demo Android APK** signed and distributed via direct download from the website. iOS via TestFlight (more friction, may skip for hackathon).

### Google AI Studio configuration in Phoenix

The `Kan.Reasoner` module reads configuration from `runtime.exs`:

```elixir
# config/runtime.exs
import Config

if config_env() == :prod do
  config :kan, Kan.Reasoner,
    adapter: Kan.Reasoner.GoogleAIStudio,
    api_key: System.fetch_env!("GOOGLE_AI_STUDIO_API_KEY"),
    base_url: "https://generativelanguage.googleapis.com/v1beta",
    default_model: "gemma-4-31b-it",
    fallback_model: "gemma-4-26b-a4b-it",
    timeout_ms: 60_000,
    stream: true,
    thinking_mode: true,                # use IT Thinking variant for legal reasoning
    safety_settings: [
      # Default Google safety thresholds; appropriate for citizen-facing use
      %{category: "HARM_CATEGORY_HARASSMENT", threshold: "BLOCK_MEDIUM_AND_ABOVE"},
      %{category: "HARM_CATEGORY_HATE_SPEECH", threshold: "BLOCK_MEDIUM_AND_ABOVE"},
      %{category: "HARM_CATEGORY_SEXUALLY_EXPLICIT", threshold: "BLOCK_MEDIUM_AND_ABOVE"},
      %{category: "HARM_CATEGORY_DANGEROUS_CONTENT", threshold: "BLOCK_ONLY_HIGH"}
    ]
end

if config_env() == :dev do
  config :kan, Kan.Reasoner,
    adapter:
      if System.get_env("GOOGLE_AI_STUDIO_API_KEY") do
        Kan.Reasoner.GoogleAIStudio
      else
        Kan.Reasoner.Mock   # uses canned responses from test fixtures
      end,
    api_key: System.get_env("GOOGLE_AI_STUDIO_API_KEY"),
    base_url: "https://generativelanguage.googleapis.com/v1beta",
    default_model: "gemma-4-31b-it",
    timeout_ms: 30_000,
    stream: true,
    thinking_mode: true
end
```

The `Kan.Reasoner.GoogleAIStudio` adapter is a thin client over Google's Gemini API endpoint (`generativelanguage.googleapis.com`), with streaming via Server-Sent Events. The endpoint shape is `POST /v1beta/models/{model}:streamGenerateContent` with request body following the Gemini API schema. Function calling uses the `tools` array with `function_declarations`, exactly as documented in Google AI Studio.

The `Kan.Reasoner.Mock` adapter is for development without an API key and for tests; it returns deterministic responses based on the input case signature.

### Minimum environment variables

```
# Phoenix
SECRET_KEY_BASE=<generated>
DATABASE_URL=postgres://kan:password@host:5432/kan
PHX_HOST=kan.gt
PHX_PORT=4000

# Google AI Studio
GOOGLE_AI_STUDIO_API_KEY=<from aistudio.google.com/app/apikey>

# Storage
SPACES_BUCKET=kan-prod
SPACES_REGION=nyc3
SPACES_ACCESS_KEY=<...>
SPACES_SECRET_KEY=<...>

# Cryptography
HASH_INDEX_SIGNING_PUBLIC_KEY=<base64 ed25519 public key>
HASH_INDEX_SIGNING_PRIVATE_KEY=<base64 ed25519 private key, server only>

# Observability (optional)
OTEL_EXPORTER_OTLP_ENDPOINT=https://api.honeycomb.io
OTEL_EXPORTER_OTLP_HEADERS=x-honeycomb-team=<key>
```

### How to obtain a Google AI Studio API key

1. Visit `https://aistudio.google.com/app/apikey`.
2. Sign in with a Google account.
3. Click "Create API key".
4. Copy the key and store it in `.env.local` (development) or as an environment variable in production.

The free tier includes substantial monthly quota for Gemma models. For the hackathon and early production, this is sufficient.

For post-hackathon production:

- Multi-tenant Phoenix on multiple Droplets behind DO Load Balancer.
- Postgres primary + standby in same region, async replica in another region via VPC peering.
- Continue with Google AI Studio while volumes are predictable. For higher-volume production with stricter SLA needs, consider migrating to **Vertex AI** (Google Cloud) which offers paid Gemma serving with stronger guarantees, or self-hosting Gemma 4 on a dedicated GPU droplet. Both are configuration changes in the `Kan.Reasoner` adapter, not architectural rewrites.
- Anonymous metrics in ClickHouse, not Postgres, when volume justifies.
- Kestra for orchestration of breach catalog updates, anchor publishing, cleanup jobs.

---

## 16. Local development setup

The goal: a new contributor clones, runs one command, has Kan running locally with synthetic data in under 10 minutes.

```bash
git clone git@github.com:kan-gt/kan-server.git
cd kan-server
cp .env.example .env.local
make dev-up                   # docker compose up of Postgres + Phoenix + MinIO
make dev-seed                 # migrations + sample breaches + sample fiscalías
curl http://localhost:4000/healthz
```

`make dev-up` brings up:
- PostgreSQL 18 (Docker image `postgres:18-alpine` from the official Docker Hub library) with native `uuidv7()` support.
- Phoenix in dev mode with hot reload.
- Google AI Studio API access (developer sets `GOOGLE_AI_STUDIO_API_KEY` in `.env.local`, obtained from `https://aistudio.google.com/app/apikey`). No local model serving. For offline development without API access, the `Kan.Reasoner` module supports a `mock` adapter that returns canned responses based on test fixtures.
- MinIO for local S3-compatible storage.
- Mailhog for outbound email testing.

For the client:
```bash
git clone git@github.com:kan-gt/kan-app.git
cd kan-app
flutter pub get
flutter run                   # runs on connected Android device
```

The first launch downloads Gemma 4 E4B IT (~3 GB cuantizado) from Hugging Face on demand.

---

## 17. Testing strategy

- **Unit tests** for Elixir modules using ExUnit. Required for `Reasoner`, `BreachCatalog`, `LegalTemplates`, all tools.
- **Integration tests** with a mocked Google AI Studio client (using `Mox` or `Bypass` in Elixir) returning fixed responses, verifying the full flow from channel input to channel output. Tests never make real Google AI Studio calls.
- **LiveView tests** using `Phoenix.LiveViewTest` for the transparency panel.
- **Flutter widget tests** for conversation UI, document preview, DPI scanner.
- **End-to-end tests with synthetic conversations**: a fixture YAML defines (audio input or text) → (expected tool calls) → (expected response shape). Run nightly.
- **Load test** the Phoenix server with `k6` or `wrk` simulating 100 concurrent reasoning streams.
- **Security review**: no secret in repo (gitleaks pre-commit). No unbounded recursion. No SQL injection via `Ecto.Query`.

---

## 18. The 18-day plan

The hackathon deadline is 18 days from May 1, 2026. Calendar:

The plan runs **two parallel tracks**: the main app track (server + client) and the Unsloth fine-tuning track. The fine-tuning can happen in parallel because it does not block the app development — the app starts with base Gemma 4 E4B IT and swaps in the LoRA adapter when ready.

**Days 1-2 — Risk reduction and benchmarks**
- Verify Gemma 4 E4B IT runs on target Android (Pixel 4a or similar Android 11 baseline) via **Cactus SDK**. Measure: cold start time, RAM peak, response latency for typical prompts, audio mode quality, vision mode OCR accuracy on DPI photos.
- If Cactus on E4B has unexpected issues on target hardware, fall back to E2B with Cactus. Decide by end of day 2.
- Verify Gemma 4 31B IT Thinking via Google AI Studio API. Measure: tokens/second with streaming, free tier limits, latency from Guatemala to Google endpoints, behavior under function calling, thinking mode quality on legal reasoning prompts.
- Pull breach data: Mintrab, Digecam, public lists. Build initial hash index.
- **Fine-tuning track:** start dataset construction. Aim for ~200 examples by end of day 2 across the three flows.

**Days 3-5 — Server core**
- Phoenix project setup, Postgres migrations, basic schema.
- Reasoner module with Google AI Studio integration, streaming, function calling, thinking mode.
- Breach catalog module with sample data.
- Legal templates module with three initial templates: denuncia MP, queja PDH, solicitud bloqueo buró.
- API endpoints and Phoenix Channel for reasoning.
- **Fine-tuning track:** continue dataset construction. Target ~500 examples by end of day 5.

**Days 6-9 — Client core**
- Flutter project, Cactus SDK integration with Gemma 4 E4B (using base model first).
- Conversation screen with voice input, streaming output, TTS.
- Local breach verification (hash lookup in SQLite).
- DPI scanner using Gemma 4 vision through Cactus multimodal.
- Local template filling and PDF generation.
- **Fine-tuning track (Days 7-9):** first training run on Colab T4 with the dataset assembled so far. Evaluate quality. Iterate on dataset.

**Days 10-12 — Integration and panel**
- Client ↔ server via Phoenix Channels with streaming.
- LiveView transparency panel at kan.gt with map, counters, event feed.
- Anonymous metrics flow end-to-end.
- WhatsApp share, print, save.
- **Fine-tuning track:** final training run with full dataset (~1000 examples). Export LoRA adapter as GGUF. Integrate adapter loading in Cactus client. Run before/after benchmarks.

**Days 13-14 — UX polish**
- Animation of thinking mode (showing Gemma 4 31B's reasoning trace in the UI).
- Voice visualizer during recording.
- Onboarding flow that explains privacy (essential for trust).
- Accessibility: large fonts, high contrast, slow-pace voice option.
- **Fine-tuning track:** write `fine_tuning/README.md` documenting reproducibility, write benchmark report comparing base vs fine-tuned outputs.

**Day 15 — Real user testing**
- Test with at least one person matching the user profile (older adult, low digital literacy). Iterate prompts and UI based on feedback.
- Fix critical issues only. No new features.

**Day 16 — Hardening**
- Error handling for offline mode, server unavailable, model crash.
- Final security review.
- Deploy to production environment (Cloudflare + Caddy + Phoenix + Google AI Studio API).
- Verify all four prize claims have visible evidence: Cactus SDK in code (Cactus Prize), Unsloth notebook + LoRA artifact + benchmark report (Unsloth Prize), accessibility features visible in demo (Digital Equity Track), full architecture executing well (Main Track).

**Day 17 — The video**
- Script: real person + real problem (Petén-style situation) + Kan working live + person empowered with denuncia in hand.
- Three minutes. Voice-over in Spanish (or with subtitles for international judges).
- Show the LiveView panel updating live during a real interaction.
- Record on actual Android device, not emulator.
- **Visibly show fine-tuning impact:** a side-by-side moment where the same prompt with base Gemma 4 E4B vs Kan's fine-tuned adapter produces different outputs, demonstrating the value of the Unsloth work.

**Day 18 — Submission**
- Writeup under 1500 words, clearly explaining: the architecture, why Gemma 4 specifically, what the demo shows. **The writeup must explicitly mention the four prize claims (Main Track, Digital Equity & Inclusivity, Cactus, Unsloth)** in dedicated paragraphs so judges route the submission appropriately.
- Public code repos: server (Phoenix), client (Flutter), and the `fine_tuning/` directory containing notebook and dataset (or links to it on Hugging Face / Kaggle Datasets if too large for GitHub).
- Live demo URL with sample DPI numbers (synthetic) for judges to test.
- LoRA adapter published to Hugging Face under a CC-BY 4.0 compatible license.
- Submit before deadline. Submit early — the brief warns: *"any un-submitted or draft Writeups will not be considered."*

---

## 19. What Kan deliberately is not

- **Not a continuous dark web monitoring service.** Uses public breach catalogs only. Companies like SpyCloud or IntelX have paid services for that.
- **Not a digital identity.** Does not replace DPI, does not sign anything, does not authenticate the user to third parties. Bacab is for that, later.
- **Not a legal practice replacement.** Provides templates and guidance; does not provide legal advice. Disclaimers must be visible.
- **Not multilingual yet.** Spanish only. Mayan languages deferred until corpora and validation are ready. Promising what cannot be honestly delivered would harm the very users we want to help.
- **Not a fraud prevention system.** Cannot stop a future fraud from happening. Helps citizens after the fact and helps them detect early.
- **Not a substitute for the cybersecurity law (initiative 6347)** or for institutional reform. Helps individuals navigate an imperfect system; does not fix it.

---

## 20. Open questions and risks

The implementing LLM and engineer should be aware of these uncertainties and bring them up if they affect a specific code decision:

1. **Audio mode of Gemma 4 E4B on Android 8-10:** untested on this exact hardware in this exact use case. Plan B with Whisper.cpp must remain ready until validated.
2. **Vision mode OCR accuracy on real DPIs:** synthetic test images may not match real-world conditions (glare, smudges, old laminate). Plan B with MLKit or Tesseract as fallback.
3. **Legal template authority:** templates need to be reviewed and signed by an actual Guatemalan lawyer or legal aid organization. For hackathon demo, prototype templates are acceptable with a disclaimer; for any production use, real legal review is mandatory.
4. **Breach data sources:** publicly disclosed breaches are easy. Underground market listings are harder and ethically complex (do we ingest them?). Decision: stick to publicly disclosed for hackathon. Reconsider for production with legal counsel.
5. **Google AI Studio quota at scale:** for hackathon and early production, Google AI Studio's free tier is sufficient. If token volume grows to thousands of reasoning requests per day, the free tier limits may be hit. Migration paths (in order of friction): (a) upgrade to paid Google AI Studio tier, (b) move to Vertex AI for production-grade Gemma serving, (c) self-host Gemma 4 on a dedicated GPU droplet. The architecture supports any of these with a configuration change in `Kan.Reasoner`.
6. **Adoption strategy:** the app being technically excellent does not mean the target user installs and uses it. Distribution requires partnerships with PDH, MP, NGOs working with vulnerable communities. This is post-hackathon work but should be planned for.

---

## 21. Coding conventions and constraints

- **Elixir:** follow the official style guide. Use `mix format`. Modules namespaced under `Kan.` and `KanWeb.`. Public functions documented with `@doc`. Typespecs (`@spec`) for public APIs.
- **Dart:** follow effective Dart guidelines. Use `dart format`. Strong null safety. State management via Riverpod or vanilla `ChangeNotifier` (prefer simpler).
- **SQL:** snake_case. Migrations are one-way (no down migrations in production); for dev, both directions are fine.
- **Logging:** structured JSON. Never log PII. Never log raw tokens from Gemma. Log decisions, not contents.
- **Error handling:** never silent. If Gemma is unreachable, the client tells the user and offers offline-only mode. If a tool fails, the conversation acknowledges it.
- **Testing:** new features come with tests. No exception. The CI pipeline rejects PRs without test coverage on changed code.
- **Comments:** explain why, not what. Code shows what. Comments explain the decision behind it.
- **Names:** Spanish for user-facing text and domain concepts in Guatemalan context (denuncia, fiscalía, DPI). English for technical code (function, variable, file names).
- **Commits:** conventional commits format. `feat:`, `fix:`, `chore:`, `docs:`, `refactor:`, `test:`. Every commit description in English.

---

## 22. The narrative anchor

When the implementing LLM faces a tradeoff and the documentation is silent, the answer comes from the narrative anchor:

**A Guatemalan grandmother in Petén, whose DPI was used three months ago to open a bank account she did not authorize, picks up her son's old Android phone, opens Kan, says "creo que me robaron mis datos", and twenty minutes later walks out of her house with a printed denuncia in hand and a clear plan for the next step.**

If a code decision makes that scenario more achievable, it is the right decision. If it makes it harder, slower, more confusing, or less private, it is the wrong one.

That scenario is what we are building. The technology is the means.

---

## 23. Final instructions to the implementing LLM

When asked to implement any part of Kan, follow these meta-rules:

1. **Read the relevant section of this document first.** Do not assume. The decisions here are deliberate.
2. **If the request would violate a privacy commitment (Section 13), refuse and explain.** Do not generate code that violates these.
3. **If the request would deviate from the tech stack (Section 8), flag it and ask for confirmation.** Sometimes deviation is correct; explicit acknowledgment matters.
4. **Prefer simplicity and readability over cleverness.** A junior Elixir or Dart engineer must be able to understand and modify the code in 6 months.
5. **Honest tradeoffs.** When making a choice, explain what you are choosing against and why. No marketing language, no "blazing fast", no superlatives without numbers.
6. **No fictional libraries.** If a package does not exist or you are uncertain about its API, say so. Suggest verifying.
7. **Test as part of the deliverable.** Code without tests is incomplete.
8. **Preserve the narrative anchor.** Section 22. Always.

End of document. Implement responsibly.