# Threat Model

## Overview

GenAI is a Hex-published Elixir **library**, not a deployed service: it has no ingress, no database, and no perimeter of its own. It executes inside consumer applications and does three security-relevant things on their behalf: (1) it holds and transmits provider API keys alongside user prompts to third-party AI APIs, (2) since the MCP tool-source adapter landed, it ingests **externally-controlled data** — tool definitions, schemas, and results from MCP servers — and republishes it to LLMs and telemetry, and (3) the `tobor-grade` CLI reads local agent transcripts and egresses their rendered contents to hosted classifier endpoints (TypeSafe Jev, Alibaba decision-model-preview), appending verdicts to a local JSONL sink. The trust boundaries that matter are consumer-process ↔ MCP server, consumer-process ↔ provider APIs, library ↔ telemetry sinks, and operator workstation ↔ grading endpoints.

Assets: provider API keys (config/env), prompt/thread content in transit, MCP tool results, consumer telemetry streams, transcript contents (may embed secrets overheard by graded agent sessions). Grounding: components and data flow in [PROJ-ARCH.md](PROJ-ARCH.md); implementing directories in [PROJ-LAYOUT.md](PROJ-LAYOUT.md); interface contracts in [PROJ-SCHEMA.md](PROJ-SCHEMA.md).

## Attack Surface

```mermaid
graph LR
    subgraph ConsumerApp [Consumer application - trusted]
        Lib[genai library code]
        Env[.envrc / mix config - API keys]
        Tele[Telemetry sinks]
    end
    Lib -->|HTTPS + Bearer/x-api-key| APIs[3rd-party provider APIs]
    Lib -->|key in URL query| Gemini[Gemini API]
    Lib -->|prompts + keys egress| APIs
    MCPS[MCP servers - untrusted]|tool defs, schemas, results| Adapter[Tool.Source.MCP adapter]
    Adapter -->|model-facing tool names + results| LLM[LLM context]
    Adapter -.opt-in.-> Tele

    TR[Local transcript JSONL] --> TG[ToborGrade CLI]
    TG -->|rendered transcript + keys egress| CE[Grading endpoints: TypeSafe Jev / Alibaba decision-model-preview]
    TG -->|verdict line append| Sink[Local jsonl sink]

    Internet -->|configurable base URLs| Lib
```

## Vulnerability Register

| ID | Severity | STRIDE | Component | Status |
|----|----------|--------|-----------|--------|
| T-001 | High | Information disclosure | Tool arguments/results recorded in registry telemetry | Mitigated — telemetry excludes payloads unless `include_payloads: true` (`lib/genai/tool/source/mcp.ex`) |
| T-002 | Medium | Information disclosure | MCP server `_meta` (opaque/sensitive vendor values) leaking into tool meta/results | Mitigated — excluded unless `include_mcp_meta: true` (trusted servers only) |
| T-003 | Medium | DoS | Remote MCP keys eroding the atom table | Mitigated — `json_safe/1` stringifies atoms/keys, never creates atoms from remote data |
| T-004 | Medium | Tampering / Spoofing | Malicious MCP server tool names colliding or mimicking other sources' tools | Partial — `source_id__tool_name` namespacing is deterministic and caller-chosen, but the tool-name half is taken verbatim from the server (`normalize_tool/2`); no charset/dedup validation |
| T-005 | Low | Information disclosure | Gemini API key travels as URL query parameter (log/proxy exposure) | Accepted — provider's design; consumers must keep request logs redacted |
| T-006 | Low | Information disclosure | `erl_crash.dump` at repo root can embed secrets from process heaps | Mitigated — gitignored; treat as sensitive artifact when present |
| T-007 | Medium | Tampering | Supply chain: Hex package `genai` poisoning | Mitigated — publish discipline w/ 2FA, `mix.lock` pinning; verify on consume |
| T-008 | Low | Spoofing | Configurable egress endpoints (`QWEN_BASE_URL`, `LITELLM_BASE_URL`, `OLLAMA_BASE_URL`, `SUNO_BASE_URL`) redirecting keys/prompts | Accepted — operator-controlled env; same trust level as the keys themselves |
| T-009 | Medium | Tampering | Prompt injection via MCP tool results entering LLM context | Accepted (library scope) — content is data to the model by design; consumers own prompting defenses |
| T-010 | Medium | Information disclosure | `tobor-grade` renders transcript contents (which may embed secrets from graded agent sessions) and egresses them to hosted classifier endpoints | Accepted — explicit operator-invoked CLI; endpoints and keys are operator env config (same trust level as T-008); no redaction layer exists in the renderer |
| T-011 | Low | Repudiation / Tampering | jsonl sink appends are unauthenticated and unbounded — a forged or concurrent-written sink cannot be distinguished from genuine grades | Accepted — local operator-owned file; consumers requiring integrity should write to append-audited storage |

## Mitigation Coverage

5 mitigated · 1 partial (T-004) · 5 accepted (T-005, T-008, T-009, T-010, T-011). No open items with code changes pending; T-004 is the only candidate hardening (validate/sanitize the server-supplied tool-name segment). The `TOBOR_GRADING=1` recursion guard keeps grading sessions from grading themselves (relevant to eval-platform loops).

## Residual Risk

MCP servers are trusted-ish by necessity: the adapter prevents mechanical leakage (payloads, `_meta`, atom bombs) but cannot make untrusted tool output *safe* — that lands in the model's context (T-009) and is the consumer's threat to manage. Provider egress is only as trustworthy as the operator's env configuration (T-008), and grading egress inherits that same trust: transcripts go out verbatim-rendered (T-010), so grade only transcripts whose exposure to the configured endpoint is acceptable.

## Maintenance

Revisit on: new providers (new key/egress paths), changes to `Tool.Source.MCP` normalization defaults, new telemetry events, changes to the `tobor-grade` renderer/sink behavior, or Hex release process changes.
