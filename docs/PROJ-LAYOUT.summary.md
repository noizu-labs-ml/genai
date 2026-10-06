# Project Layout Summary

```
genai/
├── lib/
│   ├── application.ex
│   ├── genai/tool/source/mcp.ex
│   └── genai_providers/
│       ├── anthropic.ex + anthropic/
│       ├── open_ai.ex + open_ai/ (audio, image, speech, transcription)
│       ├── gemini.ex + gemini/ (image)
│       ├── mistral.ex + mistral/
│       ├── groq.ex + groq/
│       ├── xai.ex + xai/
│       ├── deep_seek.ex + deep_seek/
│       ├── ollama.ex + ollama/
│       ├── qwen.ex + qwen/ (dashscope, image, speech, video)
│       ├── zai.ex + zai/
│       ├── cerebras.ex + cerebras/
│       ├── open_router.ex + open_router/
│       ├── litellm.ex + litellm/ (media)
│       ├── eleven_labs.ex
│       ├── suno.ex
│       ├── media_helpers.ex
│       └── media/openai_compat.ex
├── config/
├── test/
│   ├── providers/
│   ├── genai_providers/
│   ├── support/
│   ├── gen_ai_test.exs
│   ├── tool_test.exs
│   └── mcp_tool_source_test.exs
├── examples/
├── priv/media/
├── .github/workflows/
├── docs/
├── .meta/
├── mix.exs
├── mix.lock
└── README.md
```
