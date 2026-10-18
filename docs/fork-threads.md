# Forked conversation threads

`GenAI.Pipeline.fork/3` and `split/3` return a `GenAI.Thread.Fork`. It implements
the same `GenAI.ThreadProtocol` as a regular conversation. Each leaf retains its
own pipeline, messages, settings, extraction frames and artifacts.

```elixir
fork =
  GenAI.Pipeline.fork(thread,
    concise: fn pipeline ->
      %{pipeline | thread: GenAI.with_setting(pipeline.thread, :max_tokens, 64)}
    end,
    detailed: fn pipeline ->
      %{pipeline | thread: GenAI.with_setting(pipeline.thread, :max_tokens, 512)}
    end
  )

{:ok, {result, updated_fork}} = GenAI.run(fork, context, max_concurrency: 2)
{:ok, concise_completion} = GenAI.Thread.Fork.Result.fetch(result, [:concise])
```

The run result is `%GenAI.Thread.Fork.Result{operation: :run, outcomes: [...]}`.
Outcomes follow branch declaration order, including nested branches in depth
first order. Each outcome contains its full `path`, leaf `id`, `status`, and
either a `value` or a `reason`. `GenAI.run(fork)` returns `{:ok, result}` using
the same convenience form as a regular thread.

Each leaf selects its own provider and encoder. Forks can contain different
models or API styles. Providers receive regular leaf threads, so their existing
request and completion contracts apply.

Thread mutators broadcast to every leaf. Effective-value readers return an
ordered result paired with the updated fork. Pass the model projection into
model-dependent readers to preserve each branch's encoder selection:

```elixir
fork = GenAI.with_setting(updated_fork, :temperature, 0.2)
{:ok, {models, fork}} = GenAI.ThreadProtocol.effective_model(fork, context, [])
{:ok, {messages, fork}} =
  GenAI.ThreadProtocol.effective_messages(fork, models, context, [])
```

`models` and `messages` are path-keyed `Fork.Result` values. Each message value
is encoded for its own branch model; there is no implicit first-branch model.

## State and errors

Execution returns the updated fork. It does not select a winning branch or
concatenate conversations. Use explicit pipeline joins to collapse branches.
An ordinary `GenAI.run` preserves its single inference semantics; use
`GenAI.Pipeline.next_turn` when the assistant response should be appended.

If any leaf fails, execution returns
`{:error, %GenAI.Thread.Fork.Error{fork: updated_fork, result: result}}`.
Successful sibling outcomes and completed continuation state remain available.
No branch silently replaces another.

`GenAI.report` has no implemented scalar report contract. Calling it on a fork
returns `{:error, {:unsupported_fork_command, :report}}`; it does not run
inference or fabricate a report from one branch.

The `max_concurrency` and `timeout` options apply to the entire nested fork,
with one shared executor. Legacy `{:fork, branches}` inputs are normalized at
the public boundary; new operations return the thread struct.

## Streaming

```elixir
{:ok, {result, updated_fork}} =
  GenAI.stream(fork, context, stream_sink: self(), max_concurrency: 2)
```

Each successful outcome contains that leaf's normal streaming accumulator.
Sink events include the full path:

```elixir
{:genai, {:branch, [:concise], {:text, "Hello"}}}
{:genai, {:branch, [:experiment, 0], {:text, "Alternative"}}}
```

Events from concurrent leaves may interleave. Use paths to maintain separate
output buffers. A stream's returned accumulator and completion belong to that
leaf, including its finish state and usage.

This envelope applies to the default handler and configured
`GenAI.StreamHandler.Accumulate` sinks. Custom stream handlers retain their
callback contract and receive `:fork_path` in their initialization options;
handlers that publish their own events should include that path themselves.

## Tools

```elixir
{:ok, {result, updated_fork}} =
  GenAI.run_with_tools(fork, registry, context,
    max_concurrency: 2,
    max_iterations: 4,
    max_tool_calls: 8
  )

{:ok, %{completion: completion, summary: summary}} =
  GenAI.Thread.Fork.Result.fetch(result, [:concise])
```

Every leaf owns its model/tool loop. Tool calls and responses are appended to
that leaf's history before its next inference. The fork outcome value contains
the final completion and `GenAI.ToolChain.Summary`; the updated fork contains
the continuations. A failed loop retains interactions completed before its
failure. Scalar threads keep the existing
`{:ok, {completion, updated_thread, summary}}` return shape.

Tool iteration and call limits apply per leaf. Fork concurrency is global.
Thread state is immutable and isolated; external tool services, PIDs, model
handles and other resources retain their normal sharing semantics. Choose
sources that permit concurrent calls, or set `max_concurrency: 1`.

## Verification

The focused provider gate passed 66 tests. Five fork integration fixtures also
passed against the default merged Git Core source with optional ExLLama enabled
and `GENAI_CORE_PATH` unset. They cover Standard and Session leaves, native and
compatible encoders, nested streaming, configured sinks, tool continuations and
partial failures through mocked Finch transports. No live model calls are made
by these fixtures.
