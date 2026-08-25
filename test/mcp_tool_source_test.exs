if Code.ensure_loaded?(Noizu.MCP.Server) do
  defmodule GenAI.MCPToolSourceTest.Echo do
    use Noizu.MCP.Server.Tool,
      description: "Echo text through the in-VM MCP transport",
      annotations: [read_only_hint: true]

    input do
      field(:text, :string, required: true)
    end

    @impl true
    def call(%{text: "fail"}, _context), do: {:error, "requested failure"}
    def call(%{text: text}, _context), do: {:ok, %{echo: text}}
  end

  defmodule GenAI.MCPToolSourceTest.Server do
    use Noizu.MCP.Server, name: "genai_bridge_fixture", version: "1.0.0"

    tool(GenAI.MCPToolSourceTest.Echo)
  end

  defmodule GenAI.MCPToolSourceTest do
    use ExUnit.Case, async: true

    alias GenAI.Tool.{Registry, Result}
    alias GenAI.Tool.Source.MCP

    setup do
      client =
        start_supervised!(
          {Noizu.MCP.Client,
           transport: {:test, server: GenAI.MCPToolSourceTest.Server},
           client_info: %{name: "genai_bridge_test", version: "1.0.0"}}
        )

      assert :ok = Noizu.MCP.Client.await_ready(client)
      %{client: client}
    end

    test "discovers MCP tools as GenAI tools with safe metadata", %{client: client} do
      assert {:ok, [tool]} = MCP.list_tools(client, nil, [])
      assert %GenAI.Tool{name: "echo", description: description} = tool
      assert description =~ "in-VM MCP"
      assert tool.parameters["required"] == ["text"]
      assert tool.meta["protocol"] == "mcp"
      assert tool.meta["annotations"]["readOnlyHint"] == true
      refute Map.has_key?(tool.meta, "mcp_meta")
    end

    test "registers under a deterministic namespace and executes structured results", %{
      client: client
    } do
      assert {:ok, registry} = MCP.register(Registry.new(), :fixture_data, client)
      assert Registry.names(registry) == ["fixture_data__echo"]

      assert {:ok, %Result{status: :ok, source: "fixture_data", content: payload}} =
               Registry.execute(registry, %{
                 id: "call-1",
                 name: "fixture_data__echo",
                 arguments: %{"text" => "hello"}
               })

      assert payload.structured_content == %{"echo" => "hello"}
      assert payload.is_error == false
      assert [%{"type" => "text"}] = payload.content
    end

    test "maps MCP isError outcomes to an instrumentable GenAI error result", %{client: client} do
      owner = self()
      sink = fn event, measurements, metadata -> send(owner, {event, measurements, metadata}) end

      assert {:ok, registry} =
               MCP.register(Registry.new(telemetry: sink), "fixture", client)

      assert {:error, %Result{status: :error, error: payload}} =
               Registry.execute(registry, %{
                 id: "call-error",
                 name: "fixture__echo",
                 arguments: %{"text" => "fail"}
               })

      assert payload.is_error == true
      assert [%{"text" => "requested failure"}] = payload.content

      assert_received {[:genai, :tool, :execute, :stop], _, metadata}
      assert metadata.status == :error
      refute Map.has_key?(metadata, :arguments)
      refute Map.has_key?(metadata, :result)
    end
  end
else
  defmodule GenAI.MCPToolSourceUnavailableTest do
    use ExUnit.Case, async: true

    test "reports the optional dependency when MCP is not installed" do
      assert {:error, {:missing_optional_dependency, :noizu_mcp}} =
               GenAI.Tool.Source.MCP.register(GenAI.Tool.Registry.new(), :fixture, self())
    end
  end
end
