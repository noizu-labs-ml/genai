# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

GenAI is an Elixir library (v0.2.3) providing a unified interface for multiple generative AI providers including Anthropic, OpenAI, Google Gemini, Mistral, Groq, XAI, and DeepSeek. The library uses protocol-based design for extensibility and OTP supervision for reliability.

## Essential Commands

### Development
```bash
# Install dependencies
mix deps.get

# Compile the project
mix compile

# Generate documentation
mix docs

# Format code
mix format

# Run code analysis
mix credo

# Run static analysis
mix dialyzer
```

### Testing
```bash
# Run all tests
mix test

# Run a specific test file
mix test test/path/to/test_file.exs

# Run a specific test by line number
mix test test/path/to/test_file.exs:42

# Run only unit tests (skip live API tests)
mix test --exclude live --exclude advanced

# Run live API tests (requires API keys)
mix test --only live

# Run advanced feature tests
mix test --only advanced
```

## Architecture & Code Structure

### Core Components

1. **Application Supervisor** (`lib/application.ex`): OTP application managing the Finch HTTP client
2. **Provider Interface** (`lib/genai.ex`): Main module exposing the unified API
3. **Provider Implementations** (`lib/genai_providers/`): Each provider has:
   - Main module (e.g., `anthropic.ex`)
   - Models module (e.g., `anthropic_models.ex`)
   - Encoder module (e.g., `anthropic_encoder.ex`)

### Adding New AI Providers

When implementing a new provider:

1. Create provider module in `lib/genai_providers/` implementing `GenAI.InferenceProviderBehaviour`
2. Create models module defining available models with their configurations
3. Implement encoder using the `GenAI.RequestEncoder` protocol
4. Add provider tests in `test/genai_providers/`
5. Update mix.exs if new dependencies are needed

### Key Design Patterns

1. **Protocol-Based Encoding**: Each provider implements `GenAI.RequestEncoder` protocol for API-specific formatting
2. **Behavior Contracts**: Providers implement `GenAI.InferenceProviderBehaviour` ensuring consistent interface
3. **Settings Pipeline**: Use `with_*` functions for fluent configuration:
   ```elixir
   GenAI.Provider.Anthropic
   |> GenAI.with_model("claude-3-5-sonnet-20241022")
   |> GenAI.with_api_key(api_key)
   ```

### Message Structure

All providers use `GenAI.Message` structs with standardized roles:
- `:system` - System instructions
- `:user` - User messages
- `:assistant` - AI responses
- `:tool` - Tool/function outputs

### Provider-Specific Implementation Notes

- **Anthropic**: Requires separate system message, supports vision and tools
- **OpenAI**: Standard OpenAI API format, supports tools
- **Gemini**: Requires safety settings, uses "parts" for content
- **Groq**: Fast inference, OpenAI-compatible format
- **XAI/DeepSeek**: Recently added, OpenAI-compatible implementations

## Testing Strategy

- **Unit Tests**: Use Mimic for mocking HTTP requests
- **Live Tests**: Tagged with `@tag :live`, require API keys
- **Advanced Tests**: Tagged with `@tag :advanced`, test complex features
- Test files mirror source structure in `test/genai_providers/`

## Environment Configuration

API keys are configured via environment variables:
- `ANTHROPIC_API_KEY`
- `OPENAI_API_KEY`
- `GEMINI_API_KEY`
- `MISTRAL_API_KEY`
- `GROQ_API_KEY`
- `XAI_API_KEY`
- `DEEPSEEK_API_KEY`

## Common Development Tasks

### Running specific provider tests
```bash
mix test test/genai_providers/anthropic_test.exs
```

### Testing new provider implementation
```bash
# First test with mocks
mix test test/genai_providers/your_provider_test.exs --exclude live

# Then test with real API
PROVIDER_API_KEY=your-key mix test test/genai_providers/your_provider_test.exs --only live
```

### Debugging HTTP requests
The library uses Finch for HTTP. To debug requests, check the encoder output and Finch request construction in each provider module.