Change Log
==============
All notable changes to this project will be documented in this file.

## v0.0.1 - Initial Release
- Initial Text Only Generation.

## v0.0.2 - Local Model Support
- Local LLama support added for pulling in gguf models for inference.

## v0.0.3 - Vision Support and Internal Structure Update 
Warning - This update may break existing code.


- Added Vision support for OpenAI, Gemini, and Anthropic.
- Updated internal structure to allow for more advanced use cases such as prompt loops/fitness checks,
added support for how to handel local models, etc.

## v0.1.0 - Split into core and extension libraries
To use local llama you must replace 

```
config :genai_local, :local_llama,
       enabled: true,
       otp_app: :my_app
```

with 

```
config :genai_local, :local_llama,
       otp_app: :my_app
```

and add `{:genai_local, "~> 0.1"} to your dep list.

## v0.2.0
Update to use revamped core libs.

## v0.2.3 
XAI, and DeepSeek support added. 


## v0.3.11
MCP tool source adapter (`GenAI.Tool.Source.MCP`) over an already-supervised
`Noizu.MCP.Client`. Optional Hex dependency `{:noizu_mcp, "~> 0.1.6", optional: true}`.
`genai_core` bumped to `~> 0.3.4`.

## v0.3.9
OpenRouter chat provider (`GenAI.Provider.OpenRouter`): OpenAI-compatible `https://openrouter.ai/api/v1`, Bearer `OPENROUTER_API_KEY`, live `GET /models`, optional `HTTP-Referer` / `X-OpenRouter-Title` attribution headers.

## v0.3.8
Qwen/DashScope media providers: `GenAI.Provider.Qwen.Image` (qwen-image-3.0), `Qwen.Speech` (qwen3-tts-flash), `Qwen.Video` (wan2.7-t2v async poll). Keys: `DASHSCOPE_API_KEY` / `QWEN_API_KEY` / `QWEN_TOKEN_KEY`. Token-plan host via `settings[:plan] => :token_plan`.

## v0.3.7
Qwen token-plan mode: `token_plan: true` (or `mode: :token_plan`) switches the OpenAI-compatible host to `https://token-plan.ap-southeast-1.maas.aliyuncs.com/compatible-mode/v1` and Bearer auth to `token_api_key` / `QWEN_TOKEN_KEY`. On-demand `QWEN_API_KEY` + dashscope-intl remains the default.

## v0.3.6
Qwen / Alibaba Cloud Model Studio (DashScope) chat provider added. OpenAI-compatible endpoint defaults to `https://dashscope-intl.aliyuncs.com/compatible-mode/v1`, Bearer auth from `config :genai, :qwen, api_key:` (`QWEN_API_KEY`, with `DASHSCOPE_API_KEY` fallback). Catalog helpers include `qwen3.8-max`; `models/0` lists the live compatible-mode catalog. Thinking (`reasoning_content`, `enable_thinking`, `reasoning_effort`) and vision image parts are supported.

## v0.3.5
ElevenLabs media provider added (ADR-016): sync text->speech (`/v1/text-to-speech/{voice_id}`), text->sfx (`/v1/sound-generation`), and text->music (`/v1/music/compose`), `xi-api-key` auth, `ELEVENLABS_API_KEY` env fallback; registered in the default media_providers list. README refreshed (provider list, media generation shipped, ElevenLabs usage example).
