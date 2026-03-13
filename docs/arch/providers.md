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

### OpenAI-compatible (OpenAI, Groq, xAI, DeepSeek)
- Standard Bearer token auth
- Similar request/response format
- Groq, xAI, DeepSeek override only `@base_url` and minimal headers

### Gemini (unique API)
- API key passed as URL query parameter
- Content uses `parts` structure
- Safety settings support

### Ollama (local)
- Configurable `@base_url` (default `localhost:11434`)
- Uses `/api/tags` for model listing (not `/v1/models`)

## Settings Resolution

All encoders resolve settings using a priority-ordered `search_scope`:

```elixir
[options, model_settings, provider_settings, settings, config_settings]
```

First non-nil value wins. This enables per-request, per-model, and per-provider configuration overrides.
