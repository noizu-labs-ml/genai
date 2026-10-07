# Project Schema Summary

No relational store — GenAI is a Hex library. Data = mix config, env contracts, media routing registry, MCP tool interface. Details: [PROJ-SCHEMA.md](PROJ-SCHEMA.md). Core structs (`GenAI.Message`, `Thread`, `Model`, `Tool`) live in sibling `genai-core`.

## Mix config keys (`config :genai, …`)

| Key | Fields | Notable defaults |
|-----|--------|------------------|
| `:local_llama` | enabled, otp_app | `true`, `:genai` |
| `:media_providers` | ordered module list (modality router, ADR-016) | specific providers before `LiteLLM.Media` fallback |
| `:anthropic` `:openai` `:gemini` `:mistral` `:groq` `:xai` `:deepseek` `:zai` `:cerebras` | api_key | — |
| `:openrouter` | api_key, http_referer, app_title | noizu-labs-ml referer |
| `:qwen` | api_key, token_api_key, token_plan, base_url, token_plan_base_url | `token_plan: false`; DashScope intl + token-plan hosts |
| `:litellm` | api_key, base_url | `http://localhost:4000` |
| `:suno` | api_key, base_url | `https://api.sunoapi.org` |

## Env vars

`ANTHROPIC_API_KEY` · `OPENAI_API_KEY` · `GEMINI_API_KEY` · `MISTRAL_API_KEY` · `GROQ_API_KEY` · `XAI_API_KEY` · `DEEPSEEK_API_KEY` · `ZAI_API_KEY` · `CEREBRAS_API_KEY` · `OPENROUTER_API_KEY` (+`_HTTP_REFERER`, `_APP_TITLE`) · `QWEN_API_KEY` (fallback `DASHSCOPE_API_KEY`) · `QWEN_TOKEN_KEY` · `QWEN_BASE_URL` · `QWEN_TOKEN_BASE_URL` · `LITELLM_API_KEY` · `LITELLM_BASE_URL` · `SUNO_API_KEY` · `SUNO_BASE_URL` · `ELEVENLABS_API_KEY` · `OLLAMA_BASE_URL`

## MCP tool interface (`GenAI.Tool.Source.MCP`)

- Optional dep `:noizu_mcp`, runtime-checked
- Tool names: `source_id__tool_name` (stable, caller-supplied source id)
- Tool: name / description / JSON-Schema parameters / meta (`protocol: "mcp"`, title, output_schema, annotations, icons; `_meta` excluded by default)
- Result: `content` (list) / `structured_content` / `is_error` (true ⇒ `{:error, payload}`)
- Options: `include_mcp_meta`, `include_payloads`, `mcp_options`; forwards `progress`, `progress_token`, `telemetry_metadata`, `timeout`
- All output `json_safe` — no atoms created from remote keys

## Fixtures

`priv/media/kitten.jpeg` — vision/media test input.
