# test/ — Test Suites

```
test/
├── gen_ai_test.exs                 # Core GenAI module tests
├── tool_test.exs                   # Tool/function calling tests
├── mcp_tool_source_test.exs        # MCP tool source tests
├── test_helper.exs                 # Test bootstrap — configures Mimic, tags
├── providers/                      # Per-provider test files
│   ├── anthropic_test.exs
│   ├── deepseek_test.exs
│   ├── gemini_test.exs
│   ├── groq_test.exs
│   ├── mistral_test.exs
│   ├── ollama_test.exs
│   ├── open_ai_test.exs
│   ├── open_router_test.exs
│   ├── qwen_test.exs
│   ├── xai_test.exs
│   └── zai_test.exs
├── genai_providers/                # Cross-provider suites
│   ├── eleven_labs_test.exs        #   ElevenLabs voice provider
│   ├── image_provider_test.exs     #   Image generation across providers
│   ├── media_providers_test.exs    #   Media providers (Suno, LiteLLM media, …)
│   └── openai_compatible_providers_test.exs  # Shared OpenAI-compatible encoder behavior
└── support/                        # Shared test utilities
    └── common.ex                   #   Common test helpers
```

## Test Tags

- `@tag :live` — requires real API keys (excluded by default)
- `@tag :advanced` — complex feature tests (excluded by default)
- Default run: `mix test --exclude live --exclude advanced`
