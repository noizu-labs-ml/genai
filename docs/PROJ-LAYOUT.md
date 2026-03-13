# Project Layout

```
genai/
├── lib/                            # Source code → [layout/lib.md](layout/lib.md)
│   ├── application.ex              #   OTP application supervisor (Finch HTTP client)
│   └── genai_providers/            #   Provider implementations (8 providers)
├── config/                         # Mix environment configuration
│   ├── config.exs                  #   Shared config
│   ├── dev.exs                     #   Dev overrides
│   └── test.exs                    #   Test overrides (Mimic setup)
├── test/                           # Test suites → [layout/test.md](layout/test.md)
│   ├── providers/                  #   Per-provider tests (unit + live)
│   ├── support/                    #   Test helpers
│   ├── gen_ai_test.exs             #   Core module tests
│   ├── tool_test.exs               #   Tool/function calling tests
│   └── test_helper.exs             #   Test bootstrap
├── priv/                           # Private assets (gitignored)
│   └── media/                      #   Test media files
├── .github/                        # CI/CD
│   └── workflows/elixir.yml        #   Elixir CI workflow
├── docs/                           # Documentation
│   ├── PROJ-LAYOUT.md              #   This file
│   └── layout/                     #   Detailed directory breakdowns
├── .envrc                          # direnv — API keys (gitignored)
├── .tool-versions                  # asdf versions: Elixir 1.16.3, Erlang 26.2.5.6
├── .formatter.exs                  # Elixir formatter config
├── .gitignore                      # Git ignore rules
├── mix.exs                         # Project definition and dependencies
├── mix.lock                        # Dependency lock file
├── CLAUDE.md                       # Claude Code project instructions
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
- Each provider follows the same 3-file pattern: main module, encoder, models
- Provider encoder protocols are split into `encoder.ex` (implementation) and `encoder_protocol.ex` (protocol definition)
