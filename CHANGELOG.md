Change Log
==============
All notable changes to this project will be documented in this file.

## 2026-11-10
- Docs overhaul: README refreshed for 0.5.0 — install snippets `{:genai, "~> 0.5.0"}`, `gen_ai` typo, Core-Hex paragraph (Core 0.4.0 published 2026-10-18, no more git-pin claim), `noizu_mcp` `~> 0.5.0` in the MCP section, new Features bullets (classifier grading, Anthropic prompt caching) + provider list entry (Jev / System One / SystemOneRounded), tobor-grade CLI section, "Future Features" replaced by an honest roadmap; CHANGELOG reordered to descending versions with hex.pm release dates, internal drafts v0.3.6–v0.3.8 folded into the hex releases that carried them, and v0.3.0 / v0.3.2 / v0.3.3 / v0.3.4 / v0.3.10 backfilled — landed direct to `develop`.

## 2026-10-26
- Doc sweep: refresh `docs/PROJ-LAYOUT`/`PROJ-ARCH`/`PROJ-SCHEMA`/`THREAT-MODEL` (+ summaries and layout detail pages) for the classifier providers, native DashScope, and `tobor-grade` landing — corrected stale `:qwen` base-URL env claims, documented `:jev`/`QWEN_DECISION_BASE_URL`/`QWEN_NATIVE_BASE_URL` config/env surface, tobor-grade CLI flag/sink/transcript interfaces, and threat entries T-010/T-011 — landed direct to `develop`; doc-pointer seed (`.meta/pointers.yaml`, bounded starter set) via companion PR #29.

## Unreleased
- Add `tobor-grade` CLI (`mix tobor_grade` task + `mix escript.build` binary) wrapping `GenAI.Classifier.Router.classify/2`: hosted Jev `jev-latest` `:choice` transcript verdicts (`continuation | topic-switch | new-task | more-context-needed`), `--walkback N` (cap 5) retry on `more-context-needed`, Alibaba `decision-model-preview` 0-100 `:score` via `--score` reusing the SystemOne `:alibaba_rounded_hundredths` policy, `--sink jsonl:<path>` result appends (`{component?, verdict, score?, transcript_path, walkback_used, timestamp}`) and the `TOBOR_GRADING=1` recursion guard — `feature/tobor-grade` → `develop`.

## v0.5.2 - Producer dependency pickup (2026-11-10)
- `noizu_mcp` 0.5.1 → 0.6.4 — producer vuln-fix release (bandit CVE wave + jose/ecto/plug_crypto/jsv advisory re-picks upstream); mix.exs constraint raised `~> 0.5.0` → `~> 0.6.0` (the old range pins major.minor, `>= 0.5.0 and < 0.6.0` — the resolver empirically chose 0.5.3 under it, refusing 0.6.4); surgical pins held in the lock: `jsv` 0.26.2 (resolver's 0.27.0 drag reverted) and `jose` 1.11.13. Bandit/ecto/plug_crypto are optional `noizu_mcp` deps GenAI does not install, so those advisories never reach GenAI's artifact.
- `genai_core` 0.4.0 → 0.4.1 — producer vuln-fix release (mint ×17 advisories, hpax, ymlr); `~> 0.4.0` unchanged (admits 0.4.1); GenAI's lock already carried latest `mint` 1.11.0 / `hpax` 1.1.0 / `ymlr` 5.1.6, so no transitive movement; resolver drift (floki/nimble_options/shortuuid) reverted to keep the diff to the two producer entries — pickup [#36](https://github.com/noizu-labs-ml/genai/pull/36) → `develop`.

## v0.5.1 - Security dependency bumps (2026-11-10)
- `jose` 1.11.12 → 1.11.13 — EEF advisory set EEF-CVE-2026-65625…65632 (8 CVEs, local-vector ECDSA family); the `~> 1.11` constraint is unchanged, lock-only pickup.
- `jsv` 0.26.0 → 0.26.2 — EEF-CVE-2026-117680 (LOW); lock-only pickup (jsv is locked-but-undeclared in mix.exs via the optional `noizu_mcp` dependency).

## v0.5.0 - Classifiers and native DashScope (2026-10-17)
- Integrate protocol-backed fork threads, branch-keyed provider/tool-loop results and stream events; pin merged fork Core with an optional ExLLama dependency override and verify native/compatible Standard/Session continuations — [PR #24](https://github.com/noizu-labs-ml/genai/pull/24) → `develop` (merged 2026-10-17; source `4b69269`).
- Add hosted Jev/Alibaba classifiers, optional local Jev-Omni and native DashScope generation; pin merged Core with required JSON/YAML dependencies, isolate fixture mocks, reject incomplete native streams and malformed tool collections, and normalize replayed tool arguments — [PR #23](https://github.com/noizu-labs-ml/genai/pull/23) → `develop` (merged 2026-10-17; source `67b3b45`).

## v0.4.1 (2026-10-07)
Optional `noizu_mcp` dependency constraint raised from `~> 0.1.6` to `~> 0.5.0`
(0.5.1+). Resolves the version-solving conflict for apps that require
`genai ~> 0.4.0` together with `noizu_mcp ~> 0.5.x`.

## v0.4.0 - Anthropic Prompt Caching (2026-10-07)
- Response parsing: Anthropic `usage.cache_read_input_tokens` / `usage.cache_creation_input_tokens`;
Gemini `usageMetadata` (prompt/candidates/total/`cachedContentTokenCount`) instead of empty usage.
- Request side (Anthropic): `with_setting(thread, :cache_control, :ephemeral)` wraps the system
prompt as an ephemeral cache breakpoint; `TextContent.cache_control` marks individual content
blocks; the Anthropic 4-breakpoint cap is enforced with a warning.
- `genai_core` bumped to `~> 0.3.5`.

## v0.3.11 (2026-08-26)
MCP tool source adapter (`GenAI.Tool.Source.MCP`) over an already-supervised
`Noizu.MCP.Client`. Optional Hex dependency `{:noizu_mcp, "~> 0.1.6", optional: true}`.
`genai_core` bumped to `~> 0.3.4`.

## v0.3.10 (2026-08-24)
- Qwen/DashScope media providers: `GenAI.Provider.Qwen.Image` (qwen-image-3.0), `Qwen.Speech` (qwen3-tts-flash), `Qwen.Video` (wan2.7-t2v async poll). Keys: `DASHSCOPE_API_KEY` / `QWEN_API_KEY` / `QWEN_TOKEN_KEY`. Token-plan host via `settings[:plan] => :token_plan`.
- Qwen token-plan mode: `token_plan: true` (or `mode: :token_plan`) switches the OpenAI-compatible host to `https://token-plan.ap-southeast-1.maas.aliyuncs.com/compatible-mode/v1` and Bearer auth to `token_api_key` / `QWEN_TOKEN_KEY`. On-demand `QWEN_API_KEY` + dashscope-intl remains the default.

## v0.3.9 (2026-08-24)
Internal drafts v0.3.6–v0.3.8 were never separately published to Hex; their changes shipped across the same-day 0.3.9 / 0.3.10 patches.
- Qwen / Alibaba Cloud Model Studio (DashScope) chat provider added. OpenAI-compatible endpoint defaults to `https://dashscope-intl.aliyuncs.com/compatible-mode/v1`, Bearer auth from `config :genai, :qwen, api_key:` (`QWEN_API_KEY`, with `DASHSCOPE_API_KEY` fallback). Catalog helpers include `qwen3.8-max`; `models/0` lists the live compatible-mode catalog. Thinking (`reasoning_content`, `enable_thinking`, `reasoning_effort`) and vision image parts are supported.
- OpenRouter chat provider (`GenAI.Provider.OpenRouter`): OpenAI-compatible `https://openrouter.ai/api/v1`, Bearer `OPENROUTER_API_KEY`, live `GET /models`, optional `HTTP-Referer` / `X-OpenRouter-Title` attribution headers.

## v0.3.5 (2026-08-19)
ElevenLabs media provider added (ADR-016): sync text->speech (`/v1/text-to-speech/{voice_id}`), text->sfx (`/v1/sound-generation`), and text->music (`/v1/music/compose`), `xi-api-key` auth, `ELEVENLABS_API_KEY` env fallback; registered in the default media_providers list. README refreshed (provider list, media generation shipped, ElevenLabs usage example).

## v0.3.4 (2026-08-05)
Maintenance release: project metadata (`.meta/`) additions and upstream alignment.

## v0.3.3 (2026-07-27)
ZAI provider support; upstream updates.

## v0.3.2 (2026-06-25)
Maintenance release aligned with `genai_core` 0.3.2.

## v0.3.0 (2026-03-24)
Version bump driven by dependency changes.

## v0.2.3
XAI, and DeepSeek support added.


## v0.2.0
Update to use revamped core libs.

## v0.1.0 - Split into core and extension libraries
To use local llama you must replace

```
config :genai_local, :local_llama,
       enabled: true,
       otp_app: :my_app
```

with

```
config :genai_local, :local_llama,
       otp_app: :my_app
```

and add `{:genai_local, "~> 0.1"} to your dep list.

## v0.0.3 - Vision Support and Internal Structure Update
Warning - This update may break existing code.


- Added Vision support for OpenAI, Gemini, and Anthropic.
- Updated internal structure to allow for more advanced use cases such as prompt loops/fitness checks,
added support for how to handel local models, etc.

## v0.0.2 - Local Model Support
- Local LLama support added for pulling in gguf models for inference.

## v0.0.1 - Initial Release
- Initial Text Only Generation.
