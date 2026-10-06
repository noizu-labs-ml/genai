# Project Layout

```
genai/
├── lib/                            # Source code → [layout/lib.md](layout/lib.md)
│   ├── application.ex              #   OTP application supervisor (Finch HTTP client)
│   ├── genai/                      #   Extras: MCP tool source
│   └── genai_providers/            #   Provider implementations (Anthropic, OpenAI, Gemini, Mistral, Groq, xAI, DeepSeek, ZAI, Cerebras, Qwen, Ollama, LiteLLM, OpenRouter, ElevenLabs, Suno + media helpers)
├── config/                         # Mix environment configuration
│   ├── config.exs                  #   Shared config
│   ├── dev.exs                     #   Dev overrides
│   └── test.exs                    #   Test overrides (Mimic setup)
├── test/                           # Test suites → [layout/test.md](layout/test.md)
│   ├── providers/                  #   Per-provider tests (unit + live)
│   ├── genai_providers/            #   Cross-provider suites (media, image, OpenAI-compatible)
│   ├── support/                    #   Test helpers
│   ├── gen_ai_test.exs             #   Core module tests
│   ├── tool_test.exs               #   Tool/function calling tests
│   ├── mcp_tool_source_test.exs    #   MCP tool source tests
│   └── test_helper.exs             #   Test bootstrap
├── examples/                       # Runnable example scripts
│   └── openai_voice_chat_cli.exs   #   OpenAI voice chat CLI demo
├── priv/                           # Private assets (gitignored)
│   └── media/                      #   Test media files
├── .github/                        # CI/CD
│   └── workflows/elixir.yml        #   Elixir CI workflow
├── docs/                           # Documentation
│   ├── PROJ-LAYOUT.md              #   This file
│   ├── layout/                     #   Detailed directory breakdowns
│   └── arch/                       #   Architecture notes (providers, request lifecycle)
├── .meta/                          # Cross-repo pointer registry (pointers.yaml)
├── .envrc                          # direnv — API keys (gitignored)
├── .tool-versions                  # asdf versions: Elixir 1.16.3, Erlang 26.2.5.6
├── .formatter.exs                  # Elixir formatter config
├── .gitignore                      # Git ignore rules
├── mix.exs                         # Project definition and dependencies
├── mix.lock                        # Dependency lock file
├── CLAUDE.md                       # Claude Code project instructions
├── AGENT.md / AGENTS.md            # Agent instructions (kept aligned)
├── CHANGELOG.md                    # Release history
├── CONTRIBUTING.md                 # Contribution guidelines
├── README.md                       # Project entry point
├── BOOK.md                         # Extended documentation / guide
└── TODO.md                         # Planned work
```

## Key Files Requiring Setup

| File | Action |
|------|--------|
| `.envrc` | Contains API keys for all providers — run `direnv allow` after configuring |
| `.tool-versions` | Install runtimes via `asdf install` |

## Notes

- The main `GenAI` module is defined in the `genai_core` dependency, not in this repo
- Each chat provider follows the same 3-file pattern: main module, encoder, models; several also carry extra capability modules (image, speech, audio, video — see layout/lib.md)
- Provider encoder protocols are split into `encoder.ex` (implementation) and `encoder_protocol.ex` (protocol definition)
- `doc/` (ExDoc output), `erl_crash.dump`, and `genai-*.tar` snapshots at the repo root are gitignored build/release artifacts — not part of the tree
