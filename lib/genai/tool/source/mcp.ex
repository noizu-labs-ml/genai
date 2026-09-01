defmodule GenAI.Tool.Source.MCP do
  @moduledoc """
  Adapts an already supervised `Noizu.MCP.Client` to `GenAI.Tool.Source`.

  This module deliberately calls `Noizu.MCP.Client` at runtime. GenAI therefore
  keeps its Elixir 1.16 floor and consumers that do not use MCP do not need to
  install `:noizu_mcp`.

  Register clients with an explicit source id so model-facing tool names remain
  stable across restarts:

      registry = GenAI.Tool.Registry.new(telemetry: &MyApp.tool_event/3)

      {:ok, registry} =
        GenAI.Tool.Source.MCP.register(
          registry,
          :workspace,
          MyApp.MCP.Workspace,
          context,
          telemetry_metadata: %{trace_id: trace_id}
        )

      # Tools are exposed as workspace__read_file, workspace__search, ...
      GenAI.run_with_tools(thread, registry, context)

  The client process remains owned by the consumer's supervision tree. MCP
  `_meta` values are excluded by default because servers may put opaque or
  sensitive values there. Set `include_mcp_meta: true` only for trusted servers.

  GenAI registry telemetry excludes arguments and results by default. Enable
  `include_payloads: true` only when the payloads are safe to record.
  """

  @behaviour GenAI.Tool.Source

  alias GenAI.Tool.Registry

  @client_module Noizu.MCP.Client
  @forwarded_options [:progress, :progress_token, :telemetry_metadata, :timeout]

  @doc """
  Snapshots the tools exposed by a supervised MCP client into a registry.

  `source_id` is required rather than inferred from a pid. This produces a
  deterministic namespace (`source_id__tool_name`) even when process identities
  change between VM starts.
  """
  @spec register(Registry.t(), String.t() | atom(), GenServer.server(), term(), keyword()) ::
          {:ok, Registry.t()} | {:error, term()}
  def register(registry, source_id, client, context \\ nil, options \\ [])

  def register(%Registry{} = registry, source_id, client, context, options)
      when (is_binary(source_id) or is_atom(source_id)) and is_list(options) do
    with :ok <- ensure_client_available(),
         :ok <- validate_source_id(source_id) do
      Registry.register(registry, source_id, __MODULE__, client, context, options)
    end
  end

  @impl true
  def list_tools(client, _context, options) do
    with :ok <- ensure_client_available(),
         {:ok, tools} <- client_call(:list_tools, [client, mcp_options(options)]) do
      {:ok, Enum.map(tools, &normalize_tool(&1, options))}
    end
  end

  @impl true
  def call_tool(client, name, arguments, _context, options)
      when is_binary(name) and is_map(arguments) do
    with :ok <- ensure_client_available(),
         {:ok, result} <-
           client_call(:call_tool, [client, name, arguments, mcp_options(options)]) do
      payload = normalize_result(result, options)

      if payload.is_error do
        {:error, payload}
      else
        {:ok, payload}
      end
    end
  end

  defp ensure_client_available do
    if Code.ensure_loaded?(@client_module) and
         function_exported?(@client_module, :list_tools, 2) and
         function_exported?(@client_module, :call_tool, 4) do
      :ok
    else
      {:error, {:missing_optional_dependency, :noizu_mcp}}
    end
  end

  defp validate_source_id(source_id) do
    if source_id |> to_string() |> String.trim() == "" do
      {:error, :empty_mcp_source_id}
    else
      :ok
    end
  end

  defp client_call(function, arguments), do: apply(@client_module, function, arguments)

  defp normalize_tool(tool, options) do
    tool = plain_map(tool)

    metadata =
      %{
        protocol: "mcp",
        title: value(tool, :title),
        output_schema: value(tool, :output_schema) || value(tool, :outputSchema),
        annotations: value(tool, :annotations),
        icons: value(tool, :icons)
      }
      |> maybe_put_vendor_meta(value(tool, :meta), options)
      |> compact()
      |> json_safe()

    GenAI.Tool.new(
      name: value(tool, :name),
      description: value(tool, :description) || "",
      parameters:
        value(tool, :input_schema) || value(tool, :inputSchema) ||
          %{"type" => "object", "properties" => %{}},
      meta: metadata
    )
  end

  defp normalize_result(result, options) do
    result = plain_map(result)

    %{
      content:
        result
        |> value(:content)
        |> List.wrap()
        |> Enum.map(&normalize_content/1)
        |> json_safe(),
      structured_content:
        json_safe(value(result, :structured) || value(result, :structuredContent)),
      is_error: value(result, :is_error) == true || value(result, :isError) == true
    }
    |> maybe_put_vendor_meta(value(result, :meta), options)
  end

  defp normalize_content(content) do
    content
    |> plain_map()
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp mcp_options(options) do
    explicit = Keyword.get(options, :mcp_options, [])

    options
    |> Keyword.take(@forwarded_options)
    |> Keyword.merge(explicit)
  end

  defp maybe_put_vendor_meta(map, nil, _options), do: map

  defp maybe_put_vendor_meta(map, metadata, options) do
    if Keyword.get(options, :include_mcp_meta, false) do
      Map.put(map, :mcp_meta, json_safe(metadata))
    else
      map
    end
  end

  defp compact(map), do: Map.reject(map, fn {_key, value} -> is_nil(value) end)

  defp plain_map(%{__struct__: _} = struct), do: Map.from_struct(struct)
  defp plain_map(%{} = map), do: map

  defp value(map, key) do
    Map.get(map, key) || Map.get(map, Atom.to_string(key))
  end

  # Keep adapter output transport- and struct-neutral without creating atoms
  # from remote keys. Unsupported runtime terms are represented, never run.
  defp json_safe(value)
       when is_binary(value) or is_number(value) or is_boolean(value) or is_nil(value),
       do: value

  defp json_safe(value) when is_atom(value), do: Atom.to_string(value)
  defp json_safe(value) when is_list(value), do: Enum.map(value, &json_safe/1)

  defp json_safe(%{} = value) do
    Map.new(value, fn {key, item} -> {json_key(key), json_safe(item)} end)
  end

  defp json_safe(value) when is_tuple(value), do: value |> Tuple.to_list() |> json_safe()
  defp json_safe(value), do: inspect(value, limit: 20, printable_limit: 256)

  defp json_key(key) when is_binary(key), do: key
  defp json_key(key) when is_atom(key), do: Atom.to_string(key)
  defp json_key(key), do: inspect(key, limit: 10, printable_limit: 128)
end
