# Threat Model Summary

**GenAI** — Hex Elixir library; no own perimeter. Security-relevant roles: carries provider API keys + prompts to third-party AI APIs; ingests untrusted MCP server data (tool defs, schemas, results) into LLM context and telemetry.

## Trust boundaries
- Consumer process ↔ MCP servers (untrusted input)
- Consumer process ↔ provider APIs (egress with keys; Gemini key in URL)
- Library ↔ telemetry sinks (opt-in payload exposure)

## Register (9 entries)
- **Mitigated (5)**: telemetry payload exclusion (T-001) · MCP `_meta` exclusion (T-002) · no atom creation from remote keys / `json_safe` (T-003) · crash-dump gitignored (T-006) · Hex publish 2FA + lockfile (T-007)
- **Partial (1)**: MCP tool-name half taken verbatim from server — collision/mimic within namespace not validated (T-004)
- **Accepted (3)**: Gemini key-in-URL (T-005) · configurable egress base URLs redirect keys/prompts (T-008) · prompt injection via tool results is consumer scope (T-009)

## Residual risk
Adapter stops mechanical leakage; untrusted tool output safety remains the consumer's problem. Egress trust = operator env trust.
