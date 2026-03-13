# lib/ — Source Code

```
lib/
├── application.ex                  # OTP Application supervisor — starts Finch HTTP client
└── genai_providers/                # All provider implementations
    ├── anthropic.ex                # Anthropic (Claude) provider
    ├── anthropic/
    │   ├── encoder.ex              #   Request/response encoding
    │   ├── encoder_protocol.ex     #   GenAI.RequestEncoder protocol impl
    │   └── models.ex               #   Available model definitions
    ├── open_ai.ex                  # OpenAI provider
    ├── open_ai/
    │   ├── encoder.ex
    │   ├── encoder_protocol.ex
    │   └── models.ex
    ├── gemini.ex                   # Google Gemini provider
    ├── gemini/
    │   ├── encoder.ex
    │   ├── encoder_protocol.ex
    │   └── models.ex
    ├── mistral.ex                  # Mistral AI provider
    ├── mistral/
    │   ├── encoder.ex
    │   ├── encoder_protocol.ex
    │   └── models.ex
    ├── groq.ex                     # Groq provider (fast inference)
    ├── groq/
    │   ├── encoder.ex
    │   ├── encoder_protocol.ex
    │   └── models.ex
    ├── xai.ex                      # xAI (Grok) provider
    ├── xai/
    │   ├── encoder.ex
    │   ├── encoder_protocol.ex
    │   └── models.ex
    ├── deep_seek.ex                # DeepSeek provider
    ├── deep_seek/
    │   ├── encoder.ex
    │   ├── encoder_protocol.ex
    │   └── models.ex
    ├── ollama.ex                   # Ollama provider (local LLMs)
    └── ollama/
        ├── encoder.ex
        ├── encoder_protocol.ex
        └── models.ex
```

## Provider Structure Pattern

Every provider follows the same 3-file pattern:

| File | Purpose |
|------|---------|
| `{provider}.ex` | Main module — implements `GenAI.InferenceProviderBehaviour` |
| `{provider}/encoder.ex` | Request encoding helpers and HTTP construction |
| `{provider}/encoder_protocol.ex` | `GenAI.RequestEncoder` protocol implementation |
| `{provider}/models.ex` | Available model definitions with capabilities |
