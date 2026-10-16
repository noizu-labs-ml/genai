# Native DashScope generation

GenAI supports native DashScope generation through an explicit model encoder. Existing OpenAI-compatible Qwen models and Anthropic models keep their current formats. System One classification remains a separate API and configuration.

## Setup

Set the API key and **native** base URL for the same Model Studio workspace and region:

```elixir
config :genai, :qwen,
  api_key: System.get_env("DASHSCOPE_API_KEY"),
  native_base_url: System.get_env("QWEN_NATIVE_BASE_URL")
```

A native base ends in `/api/v1`, for example `https://{WorkspaceId}.ap-southeast-1.maas.aliyuncs.com/api/v1`. Replace the placeholder with your workspace ID. The constructor never guesses a workspace, transforms a compatible-mode URL, or uses the decision endpoint as a generation endpoint. Region-specific credentials must match the selected base. An explicit per-thread `:native_base_url` and `:api_key` override configuration.

```elixir
alias GenAI.Provider.Qwen

thread =
  GenAI.chat(:session)
  |> GenAI.with_model(Qwen.Models.native("qwen-plus"))
  |> GenAI.with_message(GenAI.Message.user("Summarize the synthetic ticket."))
  |> GenAI.with_setting(:enable_thinking, false)
  |> GenAI.with_setting(:max_tokens, 256)

{:ok, {completion, thread}} = GenAI.run(thread, nil, [])
```

Use `Qwen.Models.native(model_id, api: :multimodal)` for models whose native API is multimodal, including models that require that endpoint even when the current request contains only text. Verify the model's API in its Alibaba reference. `Qwen.Models.model(model_id)` continues to use the OpenAI-compatible Qwen encoder.

[Alibaba native reference and regional endpoints](https://www.alibabacloud.com/help/en/model-studio/qwen-api-via-dashscope), [API key setup](https://www.alibabacloud.com/help/en/model-studio/get-api-key).

## Format mapping

| Concern | OpenAI compatible | Anthropic | DashScope native |
|---|---|---|---|
| Request | Top-level `messages` and options | `messages`, separate `system` | `model`, `input.messages`, `parameters` |
| Tools | `tools[].function` | `tools[].input_schema` | `parameters.tools[].function`; `result_format: "message"` |
| Tool reply | `role: "tool"`, `tool_call_id` | `tool_result` content block | `role: "tool"`, `tool_call_id`, string content |
| Images | `image_url` content parts | `image` source blocks | `image` parts and multimodal endpoint |
| Assistant output | `choices[].message` | `content` blocks | `output.choices[].message` |
| Usage | `prompt_tokens`, `completion_tokens` | `input_tokens`, `output_tokens` | `input_tokens`, `output_tokens` → common prompt/completion counts |
| Streaming | SSE `choices[].delta` | Typed SSE events | `X-DashScope-SSE: enable`; `parameters.incremental_output: true` |
| Errors | Existing provider behavior | Existing provider behavior | Safe tagged HTTP/API/stream errors; raw response bodies omitted |

Native generation sends `/services/aigc/text-generation/generation`; multimodal generation sends `/services/aigc/multimodal-generation/generation`, both below the configured `/api/v1`. Tools, `tool_choice`, `parallel_tool_calls`, model-specific `tool_stream`, JSON/schema `response_format`, thinking controls and token limits belong to `parameters`. `max_tokens` and `max_completion_tokens` remain distinct. Model support and incompatible option combinations are enforced by Alibaba; GenAI does not claim every model accepts every option.

[Function calling](https://www.alibabacloud.com/help/en/model-studio/qwen-function-calling), [structured output](https://www.alibabacloud.com/help/en/model-studio/qwen-structured-output), [thinking models](https://www.alibabacloud.com/help/en/model-studio/deep-thinking).

## Content and conversion rules

- Text and images use native content parts for multimodal models. Images preserve URI or base64 media type. Text-generation models reject image content with `:multimodal_model_required`.
- Audio and other unsupported parts return explicit typed errors. They are never silently replaced by transcripts, dropped, or stringified.
- `reasoning_content` is separate from visible text. Historical reasoning is retained by default; `preserve_thinking: false` removes it from input and is also sent as a native parameter.
- Tool argument JSON is decoded with string keys. Tool results that are already strings are passed through literally; structured results are JSON encoded. Invalid structured results or completed tool arguments return tagged errors.
- Usage counts must be nonnegative integers. Request IDs are retained. Unknown finish reasons map to `:unknown`; external strings do not create atoms.
- `token_plan` remains a compatible-mode billing feature. The native generation adapter explicitly rejects that mode rather than assuming that the token-plan host supports native generation.

## Streaming

```elixir
thread = GenAI.with_stream_handler(thread, %GenAI.StreamHandler.Accumulate{sink: self()})
{:ok, {acc, thread}} = GenAI.stream(thread, nil, [])
completion = acc.completion
```

The native provider owns byte framing and forces incremental output. It supports LF/CRLF boundaries, multiline `data:`, native `event:error` plus numeric `status:`, `event:done`, and normal HTTP close without `[DONE]` after a terminal choice finish reason. It preserves cumulative usage updates, reasoning deltas, tool argument fragments and completed correlated tool calls. Empty HTTP bodies, usage-only responses and partial streams without a terminal marker return `:incomplete_native_stream`. An explicitly finished empty choice is valid. Incomplete JSON arguments or an error after partial content fail the request.

An existing Accumulate sink or custom handler callback remains active. Custom callbacks receive complete, normalized OpenAI-style SSE frames after native decoding, with the OpenAI decoder selected for their handler. Native framing is not injected into the continuing thread, so switching back to compatible-mode retains the requested handler. Returned final completion includes reasoning and tools as semantic message parts.

[Primary DashScope SDK framing implementation](https://github.com/dashscope/dashscope-sdk-python/blob/main/dashscope/common/utils.py), [native HTTP stream implementation](https://github.com/dashscope/dashscope-sdk-python/blob/main/dashscope/common/http_request.py).

## Validation

Run the normal project fixtures with restored dependencies and the co-developed
Core source (CI pins an immutable Core revision):

```sh
GENAI_CORE_PATH=/absolute/path/to/classifier-core-worktree mix test test/genai_providers/qwen_native_test.exs
```

Run the four synthetic live generation scenarios with workspace credentials and
separate compatible/native bases configured:

```sh
GENAI_LIVE_TESTS=1 GENAI_CORE_PATH=/absolute/path/to/classifier-core-worktree \
  mix test test/genai_providers/qwen_generation_live_test.exs
```

The lock-matched native/classifier fixture gate passed during development,
covering actual `GenAI.run`/`GenAI.stream` paths with mocked Finch transport,
safe HTTP errors, reasoning/tool completion, caller sinks/callbacks and native →
compatible continuation. Real `qwen-plus` compatible/native chat and tool-stream
scenarios also passed with positive usage; the compatible stream retains its
existing raw tool-delta contract while native reconstructs semantic tool calls.
These results cover synthetic text/tool requests in the configured workspace;
they do not claim live image/audio or every Alibaba model/region is supported.
