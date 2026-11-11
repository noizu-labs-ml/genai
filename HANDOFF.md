# HANDOFF — feature/qwen-image-reference (genai)

Session: f02e7456-8b9c-45c3-bd47-75f763371834 (media-prompt backend, provider leg)
Checkpoint: 2026-11-11 — owner paused work. Recon-only checkpoint; NO code changes yet.

## Identity
- Repo: git@github.com:noizu-labs-ml/genai.git
- Branch: feature/qwen-image-reference (base: origin/develop @ 5571675)
- Worktree: /Users/keithbrings/Work/Space/Noizu/Projects/genai/.claude/worktrees/feature-qwen-image-reference
- Checkpoint commit: the commit that introduced this file (`git log -1`). Sole commit on top of base.
- deps/ symlinked to main checkout (absolute path); _build/ private (first compile is full).

## Status
- DONE: recon + port-spec extraction (below).
- NOT-STARTED: image.ex changes, unit tests, live test, CHANGELOG, PR.
- LIVE qwen-image reference call: **NOT PERFORMED — Elixir image-edit path UNPROVEN.**
  This gates the no-stubs revision leg in media-tool-site. FIRST action on resume: live-verify.

## Task
Extend lib/genai_providers/qwen/image.ex (text-only today: supported_modalities input [:text] at :16;
MediaHelpers.prompt_text drops image parts) to encode reference-image content parts. Port the EXACT
multimodal body proven in Rust:
/Users/keithbrings/Work/Space/Noizu/Projects/media-tools/src/providers/qwen_image.rs:166-221.
Declare input: [:text, :image]. qwen-image-3.0-pro already registered (qwen/models.ex:132).

## Port spec (extracted from Rust source, verified)
1. Content parts: <=3 attachments, each %{"image" => "data:<mime>;base64,<b64>"} (mime default
   image/png), then ONE %{"text" => prompt_text}. Images first, text last.
2. Route: multimodal-generation when attachments present (text2image cannot accept images; workspace
   has NO text2image models => reference attachment + multimodal route MANDATORY for edits).
   URL: DashScope.multimodal_url/1 (exists; intl root https://dashscope-intl.aliyuncs.com).
3. SYNC ONLY on multimodal: X-DashScope-Async header => 403 AccessDenied "asynchronous calls" on our
   accounts (Rust :52-58, :230-236). Do not add the async header.
4. ~61s server-side connection close on sync multimodal (Rust :84-93, :246-247). Rust pins HTTP/1.1
   (h2 dies ~61s), client ceiling 360s (MEDIA_QWEN_TIMEOUT_SECS), up to 3 connection-drop retries
   (MEDIA_QWEN_RETRIES). Elixir: GenAI.Finch is a bare Finch child (lib/application.ex:14) => default
   pool protocol :http1 (matches the pin); image.ex already passes receive_timeout: 180_000.
   Consider porting the retry + larger ceiling (single attempt is a coin toss per Rust comments).
5. parameters: size — explicit "WxH" -> "W*H" (Rust size_param :370-386; existing Elixir size/1
   already replaces x->*); aspect map 1:1->1024*1024, 16:9->1280*720, 9:16->720*1280,
   4:3->1024*768, 3:4->768*1024, fallback 1024*1024 (Elixir currently lacks 4:3/3:4 + fallback);
   n; negative_prompt.
6. Response image URL: port ALL 5 pointers (Rust extract_image_url :137-146), not just the first:
   /output/choices/0/message/content/0/image, /output/results/0/url, /output/results/0/image,
   /output/task_result/results/0/url, /output/url.
7. Auth: DashScope.require_key/1 — env order DASHSCOPE_API_KEY -> QWEN_API_KEY -> QWEN_TOKEN_KEY
   (request api_key wins). Use direnv QWEN_API_KEY (sk- intl); the dc MaaS token 401s AIGC routes.

## Request facade (already supports image parts — no genai-core change needed)
- GenAI.Media.Request (genai_core hex ~> 0.4.0; GENAI_CORE_PATH env overrides to source):
  /Users/keithbrings/Work/Space/Noizu/Projects/genai-core/lib/vnext_genai/media/request.ex —
  prompt may be a string or content parts incl. image parts.
- Image part struct: %GenAI.Message.Content.ImageContent{source: {:file,path}|:base64|{:uri,url},
  type: :png|:jpeg|..., resource: {:base64,b64}|{:uri,url}}; ImageContent.new/2 base64-encodes files.
  Source: genai-core lib/vnext_genai/nodes/message/content/image_content.ex.
- MediaHelpers.prompt_text/1 (lib/genai_providers/media_helpers.ex:28-37) drops non-text parts —
  the new encoder must walk parts itself (TextContent + ImageContent).

## Resume commands
```bash
cd /Users/keithbrings/Work/Space/Noizu/Projects/genai/.claude/worktrees/feature-qwen-image-reference
mix deps.get        # deps symlinked; refresh if mix.lock differs from main checkout
mix compile
mix test --exclude live --exclude advanced
# LIVE-VERIFY FIRST (gates everything downstream): one real GenAI.generate_media call —
# model qwen-image-3.0-pro, one reference-image part, explicit size (e.g. "1600x900"),
# QWEN_API_KEY from direnv (presence-check only; NEVER print the value). ~61s/frame sync ceiling.
# Write it as @tag :live test (conventions: test/genai_providers/qwen_generation_live_test.exs,
# image_provider_test.exs; Mimic for unit tests), then:
mix test --only live
# If the live call fails: report the exact error (redacted) and STOP the provider leg — no fake success.
```

## Key files
- lib/genai_providers/qwen/image.ex (change target)
- lib/genai_providers/qwen/dashscope.ex (urls, key resolution)
- lib/genai_providers/media_helpers.ex (post_json, download, prompt_text)
- lib/genai_providers/qwen/models.ex:132 (qwen-image-3.0-pro)
- lib/application.ex:14 (GenAI.Finch)
- Rust reference: /Users/keithbrings/Work/Space/Noizu/Projects/media-tools/src/providers/qwen_image.rs

## Open questions
1. Retry policy: port Rust's 3 connection-drop retries + 360s ceiling, or keep 180s single-shot?
2. URI image parts: download->base64 (faithful to Rust data-URL body) vs pass URL through to DashScope?
3. Hex release: media-tool-site needs this code; genai is hex-published (v0.3.7). Release after
   merge, or git/path dep in the interim? (Coordinator call.)

## Hard rules (carry forward)
No jass/gnp/lacrosse. Never print secret values (env NAMES + presence-booleans only; never read
.envrc.dc). No git stash. Explicit pathspec commits only. No tests against cluster DBs.
PR -> develop; never merge; main is CI/CD-only. Trailer: Co-Authored-By: Loom <loom@therobotlives.com>