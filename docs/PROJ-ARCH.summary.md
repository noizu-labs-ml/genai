# Architecture Summary

**GenAI** — Unified Elixir interface for multiple generative AI providers (chat, media, voice) plus an MCP tool-source adapter.

## Core Abstractions (from `genai_core` dependency)
- `GenAI` — Fluent API with `with_*` settings pipeline
- `GenAI.Message` / `GenAI.Model` / `GenAI.Tool` — Domain types
- `GenAI.InferenceProviderBehaviour` — Provider contract
- `GenAI.Model.EncoderBehaviour` — Encoder contract
- `GenAI.RequestEncoder` — Protocol for dispatch
- `GenAI.Media.Router` / `Request` / `Job` — Modality-based media routing
- `GenAI.Tool.Registry` — Tool registry for `run_with_tools`

## This Repo
- `GenAI.Application` — OTP supervisor starting Finch HTTP pool
- Chat providers: Anthropic, OpenAI, Gemini, Mistral, Groq, xAI, DeepSeek, ZAI, Cerebras, Qwen, Ollama, OpenRouter, LiteLLM
- Media/voice capability modules: OpenAI (image/speech/audio/transcription), Gemini (image), Qwen (image/speech/video), LiteLLM.Media, Suno, ElevenLabs
- `GenAI.Tool.Source.MCP` — adapts supervised `Noizu.MCP.Client` into the tool registry (`source_id__tool_name` namespace; `:noizu_mcp` optional at runtime)

## Provider Families
- **Anthropic**: Unique API, custom auth, system message markup
- **OpenAI-compatible**: OpenAI, Groq, xAI, DeepSeek, ZAI, Cerebras, Qwen, OpenRouter (adds referer headers), LiteLLM (gateway `base_url`)
- **Gemini**: Unique API, key-in-URL, parts-based content
- **Ollama**: Local inference, configurable base URL
- **Media-only**: Suno (music), ElevenLabs (voice) — flat modules

## Media Routing
Ordered `:media_providers` config list; Router picks first provider declaring the (input, output) modality; LiteLLM.Media is the ordered-last gateway fallback.

## Request Flow
Settings pipeline -> Model resolution -> Encoder dispatch -> Finch HTTP -> Response parsing -> `GenAI.ChatCompletion`

## Tech Stack
Elixir 1.16+ / Erlang 26, Finch (HTTP), Jason (JSON), optional noizu_mcp, Mimic (test mocking)
