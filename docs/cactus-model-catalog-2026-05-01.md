# Cactus Model Catalog Check

Date: 2026-05-01

Source checked:

- Cactus Flutter package on pub.dev: `cactus ^1.3.0`
- Cactus model catalog endpoint used by the SDK: `get-models?sdk_name=flutter&sdk_version=1.3.0`

## Relevant Catalog Entries

| Slug | Name | Size | Tools | Vision | Cactus version |
|---|---:|---:|---:|---:|---:|
| `functiongemma-270m-pro` | FunctionGemma 3 270M Pro | 279 MB | yes | no | 1.3.0 |
| `functiongemma-270m` | FunctionGemma 3 270M | 182 MB | yes | no | 1.3.0 |
| `gemma3-270m-pro` | Gemma 3 270M Pro | 278 MB | no | no | 1.3.0 |
| `gemma3-1b-pro` | Gemma 3 1B Pro | 1280 MB | no | no | 1.3.0 |
| `gemma3-270m` | Gemma 3 270M | 172 MB | no | no | 1.0.2 |
| `gemma3-1b` | Gemma 3 1B | 642 MB | no | no | 1.0.2 |

## Decision

Use `functiongemma-270m-pro` as the default Cactus benchmark slug because it is current for Cactus 1.3.0, small enough for emulator/device testing, and supports tool calling.

Do not claim this as Gemma 4 evidence. The catalog check did not show a Gemma 4 slug. For the Gemma 4 Good submission, Kan still needs separate verified Gemma 4 use, likely through Google AI Studio first, or through a local runtime only after a real Gemma 4-compatible mobile model is available and benchmarked.
