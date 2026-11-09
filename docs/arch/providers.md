# Provider Architecture

## Three-Layer Pattern

Every provider consists of three modules:

```
GenAI.Provider.{Name}           # Main module — uses InferenceProviderBehaviour
GenAI.Provider.{Name}.Encoder   # Request encoder — uses Model.EncoderBehaviour
GenAI.Provider.{Name}.Models    # Model catalog — convenience functions returning GenAI.Model structs
```

Plus a protocol implementation:

```
GenAI.Provider.{Name}.EncoderProtocol  # Protocol + impls for GenAI.Message, GenAI.Tool, etc.
```

## Provider Module

Each provider module (`use GenAI.InferenceProviderBehaviour`) provides:

- `models/0,1` — lists available models from the provider API
- `headers/1` — builds auth headers from settings
- `api_call/3` — executes HTTP requests via `GenAI.Finch`

The `@base_url` module attribute defines the provider's API root.

## Encoder Module

Each encoder (`use GenAI.Model.EncoderBehaviour`) implements:

| Callback | Purpose |
|----------|---------|
| `endpoint/5` | Returns `{method, url}` for the completion API |
| `headers/5` | Builds request headers (auth, version, content-type) |
| `default_hyper_params/5` | Declares supported hyperparameters |
| `completion_response/6` | Parses JSON response into `GenAI.ChatCompletion` |

## EncoderProtocol

The per-provider `EncoderProtocol` handles encoding of domain types into provider-specific JSON:

- `GenAI.Message` — role mapping, content encoding
- `GenAI.Tool` — tool/function schema formatting
- `GenAI.Message.ToolUsage` — assistant messages with tool calls
- `GenAI.Message.ToolResponse` — tool result formatting

A shared `EncoderProtocolHelper` module in each provider handles content-type dispatch (text, image, audio, tool calls).

## Provider Families

### Anthropic (unique API)
- Separate system message handling (wrapped in markup tags)
- Custom auth header (`x-api-key`, `anthropic-version`)
- Supports vision, tools, thinking content
- Prompt caching: `cache_control` ephemeral breakpoints — system prompt via `with_setting(thread, :cache_control, :ephemeral)` or per-block `TextContent.cache_control`; the 4-breakpoint cap is enforced and cache read/creation token usage is parsed into responses

### OpenAI-compatible (OpenAI, Groq, xAI, DeepSeek, ZAI, Cerebras, Qwen, OpenRouter, LiteLLM)
- Standard Bearer token auth
- Similar request/response format
- Groq, xAI, DeepSeek override only `@base_url` and minimal headers
- ZAI overrides chat path to `/api/paas/v4/chat/completions`
- Qwen (Alibaba DashScope) defaults to `https://dashscope-intl.aliyuncs.com/compatible-mode/v1`; `token_plan: true` uses the Singapore token-plan host + `QWEN_TOKEN_KEY`; parses `reasoning_content` and accepts `enable_thinking` / `reasoning_effort`
- OpenRouter adds attribution headers (`http_referer`, `app_title` from config)
- LiteLLM targets a self-hosted/managed LiteLLM gateway (`base_url` configurable, default `http://localhost:4000`)

### Gemini (unique API)
- API key passed as URL query parameter
- Content uses `parts` structure
- Safety settings support

### Ollama (local)
- Configurable `@base_url` (default `localhost:11434`)
- Uses `/api/tags` for model listing (not `/v1/models`)

### Classifier providers (Jev, System One)

Classifier providers implement `GenAI.Classifier.ProviderBehaviour` (not the chat
inference behaviour); `run/3` and `stream/3` return `{:error, :classifier_only_provider}`.

- **`GenAI.Provider.Jev`** (`jev.ex`, `jev/models.ex`) — hosted TypeSafe Jev classifier; capabilities `:choice` / `:boolean` / `:score`, text modality, up to 255 choices. `Jev.models/1` reads the hosted catalog (aliases such as `jev-latest`; pinned model IDs accepted).
- **`GenAI.Provider.SystemOne`** (`system_one.ex`) — shared TypeSafe System One wire adapter used by Jev and other hosted classifiers: all external keys stay strings, score indices are validated before remapping, boolean thresholds are explicit (no invented confidence). `decision-model-preview` requests apply the `:alibaba_rounded_hundredths` distribution policy; everything else uses `:strict`.
- **`GenAI.Provider.SystemOne.Rounded`** (`system_one_rounded.ex`) — the Alibaba rounded-hundredths normalization policy (grid-snapped probability repair; an inferred wire policy, not recovery of a hidden distribution).
- **`GenAI.Provider.Jev.Local`** (`jev/local.ex`) — optional local Jev-Omni bridge; consumers install ExLLama and load a classifier explicitly (source-integration opt-in via `GENAI_EX_LLAMA_PATH`). GenAI carries no native build dependency.

## Media & Voice Providers

Beyond chat, several providers expose capability modules used by `GenAI.Media.Router` (see `config :genai, :media_providers`):

- **OpenAI**: `image.ex`, `speech.ex`, `audio.ex`, `transcription.ex`
- **Gemini**: `image.ex`
- **Qwen**: `image.ex`, `speech.ex`, `video.ex` (+ `dashscope.ex` host/credential handling)
- **LiteLLM**: `media.ex` — gateway fallback for modalities without a direct provider
- **Suno** (`suno.ex`) and **ElevenLabs** (`eleven_labs.ex`): flat single-module providers (music, voice) — no encoder/models directory
- `media_helpers.ex` and `media/openai_compat.ex` hold shared plumbing (polling, OpenAI-compatible media API calls)

## Settings Resolution

All encoders resolve settings using a priority-ordered `search_scope`:

```elixir
[options, model_settings, provider_settings, settings, config_settings]
```

First non-nil value wins. This enables per-request, per-model, and per-provider configuration overrides.
