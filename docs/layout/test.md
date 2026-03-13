# test/ — Test Suites

```
test/
├── gen_ai_test.exs                 # Core GenAI module tests
├── tool_test.exs                   # Tool/function calling tests
├── test_helper.exs                 # Test bootstrap — configures Mimic, tags
├── providers/                      # Per-provider test files
│   ├── anthropic_test.exs
│   ├── deepseek_test.exs
│   ├── gemini_test.exs
│   ├── groq_test.exs
│   ├── mistral_test.exs
│   ├── ollama_test.exs
│   ├── open_ai_test.exs
│   └── xai_test.exs
└── support/                        # Shared test utilities
    └── common.ex                   #   Common test helpers
```

## Test Tags

- `@tag :live` — requires real API keys (excluded by default)
- `@tag :advanced` — complex feature tests (excluded by default)
- Default run: `mix test --exclude live --exclude advanced`
