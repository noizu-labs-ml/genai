# lib/ — Source Code

```
lib/
├── application.ex                  # OTP Application supervisor — starts Finch HTTP client
├── genai/                          # Core-adjacent extras
│   └── tool/source/mcp.ex          #   MCP tool source (tools served over MCP)
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
    │   ├── models.ex
    │   ├── audio.ex                #   Audio API
    │   ├── image.ex                #   Image generation
    │   ├── speech.ex               #   Text-to-speech
    │   └── transcription.ex        #   Audio transcription
    ├── gemini.ex                   # Google Gemini provider
    ├── gemini/
    │   ├── encoder.ex
    │   ├── encoder_protocol.ex
    │   ├── models.ex
    │   └── image.ex                #   Image generation
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
    ├── ollama/
    │   ├── encoder.ex
    │   ├── encoder_protocol.ex
    │   └── models.ex
    ├── qwen.ex                     # Qwen / Alibaba DashScope (compatible-mode + token plan)
    ├── qwen/
    │   ├── encoder.ex
    │   ├── encoder_protocol.ex
    │   ├── models.ex
    │   ├── dashscope.ex            #   DashScope host/credential handling
    │   ├── image.ex                #   Image generation
    │   ├── speech.ex               #   Text-to-speech
    │   └── video.ex                #   Video generation
    ├── zai.ex                      # ZAI (GLM) provider
    ├── zai/
    │   ├── encoder.ex
    │   ├── encoder_protocol.ex
    │   └── models.ex
    ├── cerebras.ex                 # Cerebras provider
    ├── cerebras/
    │   ├── encoder.ex
    │   ├── encoder_protocol.ex
    │   └── models.ex
    ├── open_router.ex              # OpenRouter provider
    ├── open_router/
    │   ├── encoder.ex
    │   ├── encoder_protocol.ex
    │   └── models.ex
    ├── litellm.ex                  # LiteLLM gateway provider
    ├── litellm/
    │   ├── encoder.ex
    │   ├── encoder_protocol.ex
    │   ├── models.ex
    │   └── media.ex                #   Media generation via LiteLLM
    ├── eleven_labs.ex              # ElevenLabs (voice) provider — flat module
    ├── suno.ex                     # Suno (music) provider — flat module
    ├── media_helpers.ex            # Shared helpers for media providers
    └── media/
        └── openai_compat.ex        # OpenAI-compatible media API plumbing
```

## Provider Structure Pattern

Chat providers follow the same 3-file pattern (capability modules appended as needed):

| File | Purpose |
|------|---------|
| `{provider}.ex` | Main module — implements `GenAI.InferenceProviderBehaviour` |
| `{provider}/encoder.ex` | Request encoding helpers and HTTP construction |
| `{provider}/encoder_protocol.ex` | `GenAI.RequestEncoder` protocol implementation |
| `{provider}/models.ex` | Available model definitions with capabilities |
| `{provider}/{capability}.ex` | Optional extras: `image`, `speech`, `audio`, `transcription`, `video`, `media` |

Media-only providers (ElevenLabs, Suno) skip the directory entirely and live in a single flat module.
