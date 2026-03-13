# Architecture Summary

**GenAI** — Unified Elixir interface for 8 generative AI providers.

## Core Abstractions (from `genai_core` dependency)
- `GenAI` — Fluent API with `with_*` settings pipeline
- `GenAI.Message` / `GenAI.Model` / `GenAI.Tool` — Domain types
- `GenAI.InferenceProviderBehaviour` — Provider contract
- `GenAI.Model.EncoderBehaviour` — Encoder contract
- `GenAI.RequestEncoder` — Protocol for dispatch

## This Repo
- `GenAI.Application` — OTP supervisor starting Finch HTTP pool
- 8 provider implementations (Anthropic, OpenAI, Gemini, Mistral, Groq, xAI, DeepSeek, Ollama)
- Each provider: main module + encoder + models + encoder protocol

## Provider Families
- **Anthropic**: Unique API, custom auth, system message markup
- **OpenAI-compatible**: OpenAI, Groq, xAI, DeepSeek — similar format, different base URLs
- **Gemini**: Unique API, key-in-URL, parts-based content
- **Ollama**: Local inference, configurable base URL

## Request Flow
Settings pipeline -> Model resolution -> Encoder dispatch -> Finch HTTP -> Response parsing -> `GenAI.ChatCompletion`

## Tech Stack
Elixir 1.16+ / Erlang 26, Finch (HTTP), Jason (JSON), Mimic (test mocking)
