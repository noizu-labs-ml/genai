# Classifier providers

GenAI 0.5.0 requires Core 0.4.0. Until Core is published, normal source checkouts
use merged Core Git commit `a98208599ab003f6ef1cc8ffdb01e91d01d5331b`.
Set `GENAI_CORE_PATH` to override it with a local classifier Core checkout.
Before publishing this GenAI version to Hex, switch the dependency to released
Core `~> 0.4.0`; source testing and PRs do not require publication.
Ordinary GenAI compilation has no native ExLLama
dependency. To run source integration with the local backend, additionally set
`GENAI_EX_LLAMA_PATH` to the ExLLama classifier checkout before restoring dependencies.

## Hosted Jev and Alibaba

`GenAI.Provider.Jev.Models.latest/0`, `preview/0`, and `model/1` return classifier
model references. `Models.list/1` discovers TypeSafe's `models[]` / `name` catalog.
Hosted classification uses `https://api.typesafe.ai/v1/systemone` by default and
`JEV_API_KEY` (`TYPESAFE_API_KEY` fallback). Override `JEV_BASE_URL` when needed.

`GenAI.Provider.Qwen.Models.decision_model_preview/0` selects Alibaba's classifier.
Set `QWEN_DECISION_BASE_URL` to the actual workspace compatible-mode `/v1` base.
The adapter appends `/systemone` once. It uses `QWEN_API_KEY` or a configured
`decision_api_key`; ordinary Qwen chat/token-plan configuration stays separate.
No private workspace URL is a package default.

```elixir
alias GenAI.Classifier.{Question, Request}

request = %Request{
  input: "Synthetic duplicate payment ticket",
  model: GenAI.Provider.Jev.Models.latest(),
  questions: [%Question{id: "route", choices: ["billing", "technical"]}]
}

{:ok, result} = GenAI.classify(request)
```

Native choice distributions are reordered by requested IDs. Provider confidence
is preserved separately from the selected probability. Native `noul` is P(yes):
the adapter records it, derives `[1-p, p]`, and uses strict `p > boolean_threshold`
(default 0.5, ties false). No Noul confidence is invented. Native score is an
expected zero-based **index**: it is checked against the returned distribution,
then mapped to the caller's numeric rubric. Raw index expectation and legend
remain in answer metadata; a discrete grade is not fabricated. Score questions
have a conservative 10-level cap; choices allow up to 255.

## Optional local Jev-Omni

```elixir
{:ok, loaded} = GenAI.Provider.Jev.Local.load(model_gguf_path, converted_head_path,
  model_id: "akhilaaa3/Jev-Omni")
request = %{request | model: GenAI.Provider.Jev.Local.model()}
{:ok, result} = GenAI.classify(request, classifier: loaded)
```

Consumers install ExLLama explicitly. An unavailable backend or missing loaded
classifier returns a tagged error. Each backend question executes a native forward
pass. The GenAI bridge imports no native structs and strips unrelated backend
metadata; usage retains only nonnegative integer counts.
The loaded `model_id` must match the request's model reference. Supply the same
custom name to `Local.load(..., model_id: name)` and `Local.model(name)` when
using a different local identity; the backend's load default is the GGUF path.
This integration was validated against ExLLama implementation commit
`cf7520d1633c2f9b433cb7772a535f7050baf92d` with the real Q8 Jev-Omni backbone
and trained decision head. Install that source explicitly when testing the
co-developed local integration; ordinary GenAI compilation remains native-free.

## Verification commands and present limits

```sh
GENAI_CORE_PATH=/absolute/core/classifier/worktree mix test \
  test/genai_providers/classifier_providers_test.exs test/providers/qwen_test.exs
```

Live tests are tagged and use synthetic state only. Explicit live execution must
have actual credentials, endpoint, chat model and optional local assets. Missing
prerequisites fail; an excluded live test is not successful inference.

```sh
GENAI_LIVE_TESTS=1 GENAI_CORE_PATH=/absolute/core/classifier/worktree \
  mix test test/genai_providers/classifier_live_test.exs --only provider:jev

# For Alibaba, configure QWEN_DECISION_BASE_URL first; provider:alibaba checks
# real 10-level score behavior and preserves the raw native index expectation.
# For local, configure GENAI_EX_LLAMA_PATH, GENAI_JEV_MODEL_PATH and
# GENAI_JEV_HEAD_PATH; use --only provider:local after native compilation.
```

Inline and fork live cases also require `QWEN_API_KEY` and
`GENAI_LIVE_CHAT_MODEL`. They validate dynamic inference-extracted criteria,
correlated tool result insertion and exactly one continuing turn with preserved
history after branch selection.

**Current verification:** the review-fix default-dependency test run passed 68 offline
fixtures (34 native, 27 classifier/pipeline integration, 7 existing Qwen), with
zero failures and four explicitly excluded live/advanced cases. All four Qwen
compatible/native chat/tool-stream live cases passed. Alibaba's direct
multi-question classification, dynamic extraction/classification/continuation,
and fork selection with one continuing turn all passed. Hosted Jev's direct,
inline and fork scenarios also passed (three live cases, six other-provider
cases excluded). The real local Jev-Omni Q8 bridge's direct, inline and fork
cases also passed (three live cases, six other-provider cases excluded).
The local run used matching model identity, GPU layers 99, context 2048 and
batch/microbatch 256, and retained all history/correlated-tool/one-turn checks.
CI checks out Core commit
`a98208599ab003f6ef1cc8ffdb01e91d01d5331b` into `.ci/genai-core` and sets
`GENAI_CORE_PATH`, rather than silently using an old/default Core version.
No package publication is required for source-path testing.

## Alibaba rounded-hundredths policy

Only Qwen requests whose actual encoded model is `decision-model-preview`
default to `distribution_policy: :alibaba_rounded_hundredths`. Jev, other models,
and Core retain strict validation. Pass `distribution_policy: :strict` to require
unit wire mass and native-score consistency within the existing `1e-6` bounds:

```elixir
GenAI.classify(request, distribution_policy: :strict)
```

This policy is **inferred from observed wire precision**, not an official Alibaba
guarantee. Controlled live responses had ten complete probability entries on a
hundredth grid, mass `0.99`, and a separately rounded native index score `2.27`.
Their displayed raw and normalized index means were `2.23` and `2.252525…`.
The [official API reference](https://www.alibabacloud.com/help/en/model-studio/decision-model-api)
states that probabilities sum to one but specifies no serialization tolerance.

Previously valid strict responses retain their existing behavior, including
high-precision vectors and more than ten choices. The rounding extension requires
exact complete keys, finite probabilities in `[0,1]`, a
hundredth grid, and 2–10 entries. Mass error cannot exceed
`min(entry_count * 0.005, 0.01)` plus a `1e-10` floating-point allowance.
Clipped rounding bins of ±`0.005` must admit an underlying unit-mass vector.
For scores, bounded allocation computes the lowest/highest attainable index
expectations; the hundredth-grid native score must fall within those bounds
plus its own ±`0.005` rounding allowance. Legends, confidence, selection and
other structural checks remain strict. A score discrepancy is checked even
when the displayed probabilities already sum to one.

Accepted probabilities are unit-normalized **estimates from displayed values**,
not recovered hidden probabilities. Canonical expected scores are computed
from those estimates and the caller's numeric rubric; no chosen grade is
fabricated. Native choice identity and provider confidence remain unchanged,
while selected probability comes from the canonical vector. Answer metadata
retains wire mass, native score (`wire_expected_index`), raw/canonical index
means, attainable bounds, policy name, and explicit inferred provenance.
Rounding fallback is limited to ten entries; larger vectors must satisfy strict
validation. Use strict mode to disable the inferred extension entirely.
