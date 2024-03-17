# GenAI

```elixir
Mix.install([
  {:genai, "~> 0.0.1"},
  {:kino, "~> 0.12.0"}
])

Application.put_env(:genai, :mistral, api_key: System.get_env("MISTRAL_API_KEY"))
Application.put_env(:genai, :gemini, api_key: System.get_env("GEMINI_API_KEY"))
Application.put_env(:genai, :openai, api_key: System.get_env("OPENAI_API_KEY"))
Application.put_env(:genai, :anthropic, api_key: System.get_env("ANTHROPIC_API_KEY"))
```

## Chat Form

```elixir
defmodule ChatTree do
  def start_link do
    :ets.new(:conversation_history, [:set, :public, :named_table])
    :ets.insert(:conversation_history, {{[], :next}, nil})
    {:ok, :started}
  end

  def reset() do
    :ets.delete_all_objects(:conversation_history)
  end

  def next_node do
    next_node([])
  end

  defp next_node(acc) do
    case :ets.lookup(:conversation_history, {acc, :next}) do
      [{_, x}] when is_integer(x) -> next_node(acc ++ [x])
      # Default path if not found
      _ -> acc ++ [0]
    end
  end

  def next_child([]) do
    next_child([0])
  end

  def next_child([p]) do
    if :ets.lookup(:conversation_history, {[p + 1], :node}) != [] do
      next_child([p + 1])
    else
      [p + 1]
    end
  end

  def next_child(path) do
    [t | p] = Enum.reverse(path)
    p = Enum.reverse(p)
    n = p ++ [t + 1]

    if :ets.lookup(:conversation_history, {n, :node}) != [] do
      next_child(n)
    else
      n
    end
  end

  def insert_node(path, node) do
    p = next_child(path)
    :ets.insert(:conversation_history, {{p, :node}, node})
    select_node(p)
  end

  def append_node(node) do
    p = next_node()
    :ets.insert(:conversation_history, {{p, :node}, node})
    select_node(p)
  end

  defp select_node(path) do
    :ets.lookup(:conversation_history, {path, :node})

    if :ets.lookup(:conversation_history, {path, :node}) != [] do
      [t | p] = Enum.reverse(path)
      p = Enum.reverse(p)
      :ets.insert(:conversation_history, {{p, :next}, t})
    end
  end

  def node_list do
    p =
      next_node()
      |> Enum.slice(0..-2//1)

    Enum.map_reduce(p, [], fn n, acc ->
      acc = acc ++ [n]

      case :ets.lookup(:conversation_history, {acc, :node}) do
        [{_, value}] -> {value, acc}
        # In case the node is not found
        _ -> {:error, acc}
      end
    end)
    |> elem(0)
  end
end
```

```elixir
frame = Kino.Frame.new()

inputs = [
  message: Kino.Input.text("Message")
]

form = Kino.Control.form(inputs, submit: "Send", reset_on_submit: [:message])

ChatTree.node_list()
|> Enum.map(fn msg ->
  content = Kino.Markdown.new("**Msg:**\n#{inspect(msg, pretty: true)}")
  Kino.Frame.append(frame, content)
end)
```

```elixir
Kino.listen(form, fn %{data: %{message: message}, origin: _origin} ->
  msg = %GenAI.Message{role: :user, content: message}
  content = Kino.Markdown.new("**Msg:**\n#{inspect(msg, pretty: true)}")
  Kino.Frame.append(frame, content)
  ChatTree.append_node(msg)
  convo = ChatTree.node_list()

  {:ok, x} =
    GenAI.chat()
    |> GenAI.with_model(GenAI.Provider.Mistral.Models.mistral_small())
    |> GenAI.with_setting(:temperature, 0.7)
    |> GenAI.with_messages(convo)
    |> GenAI.run()

  with %{choices: [%{message: msg} | _]} <- x do
    IO.puts("MATCH)")
    ChatTree.append_node(msg)
    content = Kino.Markdown.new("**Msg:**\n#{inspect(msg, pretty: true)}")
    Kino.Frame.append(frame, content)
  end
end)

:ok
```

```elixir
frame
```

```elixir
form
```
