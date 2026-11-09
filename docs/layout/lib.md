# lib/ — Source Code

```
lib/
├── application.ex                  # OTP Application supervisor — starts Finch HTTP client
├── genai/                          # Core-adjacent extras
│   └── tool/source/mcp.ex          #   MCP tool source (tools served over MCP)
├── tobor_grade.ex                  # Transcript grading CLI core (classify loop, walkback, jsonl sink)
├── tobor_grade/
│   ├── cli.ex                      #   escript entry point (mix escript.build)
│   └── transcript.ex               #   JSONL transcript loader/renderer + walk-back
├── mix/tasks/tobor_grade.ex        # `mix tobor_grade` task — same flags/exit codes as the escript
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
    ├── qwen.ex                     # Qwen / Alibaba DashScope (compatible-mode + token plan; delegates classify/2 to Qwen.Classifier)
    ├── qwen/
    │   ├── encoder.ex
    │   ├── encoder_protocol.ex
    │   ├── models.ex
    │   ├── dashscope.ex            #   DashScope host/credential handling
    │   ├── classifier.ex           #   Alibaba decision-model-preview classifier (workspace System One endpoint)
    │   ├── native.ex               #   Native DashScope generation provider (explicit native_base_url)
    │   ├── native/
    │   │   ├── encoder.ex          #     Native request encoding + credentials
    │   │   ├── messages.ex         #     Native message mapping
    │   │   ├── response.ex         #     Native response normalization
    │   │   └── stream_decoder.ex   #     SSE stream decoding (rejects incomplete streams)
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
    ├── jev.ex                      # Hosted TypeSafe Jev classifiers (choice/boolean/score; no chat text)
    ├── jev/
    │   ├── local.ex                #   Optional local Jev-Omni classifier variant
    │   └── models.ex               #   jev-latest / preview model references + catalog discovery
    ├── system_one.ex               # Shared TypeSafe System One wire adapter (all classifiers)
    ├── system_one_rounded.ex       # Inferred Alibaba score-distribution policy (SystemOne.Rounded)
    ├── media_helpers.ex            # Shared helpers for media providers
    └── media/
        └── openai_compat.ex        # OpenAI-compatible media API plumbing
```

Classifier contracts (`GenAI.Classifier.{ProviderBehaviour,Request,Question,Result,…}` and `GenAI.Classifier.Router`) live in `genai_core`; this repo contributes the adapters above. See [../classifier-providers.md](../classifier-providers.md) and [../dashscope-native.md](../dashscope-native.md).

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
