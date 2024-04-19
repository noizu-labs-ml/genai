defmodule GenAI.Tag do
  @vsn 1.0
  defstruct [
    name: nil,
    options: [],
    vsn: @vsn
  ]
end

defmodule GenAI.TagBehaviour do

end

defmodule GenAI.Loop do
  @vsn 1.0
  defstruct [
    to: nil,
    iterator: nil,
    options: [],
    vsn: @vsn
  ]
end

defmodule GenAI.LoopBehaviour do

end

defmodule GenAI.EarlyStopLambda do
  @vsn 1.0
  defstruct [
    sentinel: nil,
    vsn: @vsn
  ]
end

defmodule GenAI.EarlyStopBehavior do

end

defmodule GenAI.Score.Basic do
  @vsn 1.0
  defstruct [
    vsn: @vsn
  ]
end

defmodule GenAI.ScoreBehavior do

end

defmodule GenAI.Fitness.Basic do
  @vsn 1.0
  defstruct [
    vsn: @vsn
  ]
end

defmodule GenAI.FitnessBehaviour do

end

defmodule GenAI.MessageMutateBehaviour do

end

defmodule GenAI.PromptTune.Simple do
  @vsn 1.0
  defstruct [
    prompt: nil,
    vsn: @vsn
  ]
end

defmodule GenAI.ApiKeyBehaviour do

end
defmodule GenAI.ApiOrgBehaviour do

end
defmodule GenAI.ToolBehaviour do

end
defmodule GenAI.ModelBehaviour do

end
defmodule GenAI.SettingBehaviour do

end
defmodule GenAI.SafetySettingBehaviour do

end
defmodule GenAI.MessageBehaviour do

end
defmodule GenAI.SafetySetting do
  @vsn 1.0
  defstruct [
     setting: nil,
     value: nil,
     vsn: @vsn
  ]
end

defmodule GenAI.ApiKey do
  @vsn 1.0
  defstruct [
    provider: nil,
    key: nil,
    vsn: @vsn
  ]
end

defmodule GenAI.ApiOrg do
  @vsn 1.0
  defstruct [
    provider: nil,
    org: nil,
    vsn: @vsn
  ]
end

defmodule GenAI.Node do
  @vsn 1.0

   defstruct [
     id: nil,
     type: nil,
     handle: nil,
     content: nil,
     children: MapSet.new([]),
     vsn: @vsn
  ]

   def new(type, content, handle \\ nil) do
     %__MODULE__{
       id: UUID.uuid4(),
       type: type,
       handle: handle,
       content: content
     }
   end
end

defmodule GenAI.Tree do
  @vsn 1.0

  defstruct [
    selection: %{},
    nodes: %{},
    handles: %{},
    root: nil,
    path: [],
    vsn: @vsn
  ]

  #-----------------------
  #
  #-----------------------
  def to_list(tree)
  def to_list({:ok, %__MODULE__{} = tree}), do: to_list(tree)
  def to_list({:error, _} = error), do: error
  def to_list(%__MODULE__{} = tree), do: do_to_list(tree, tree.root)

  #-----------------------
  #
  #-----------------------
  defp do_to_list(tree, n, visited \\ [], acc \\ [])
  defp do_to_list(_, nil, _, acc), do: {:ok, Enum.reverse(acc)}
  defp do_to_list(%__MODULE__{} = tree, n, visited, acc) do
    unless n in visited do
      do_to_list(tree, tree.selection[n], [n|visited], [tree.nodes[n] | acc])
    else
      {:error, {:cyclical_path, n}}
    end
  end

  #-----------------------
  #
  #-----------------------
  def active_path(tree)
  def active_path({:ok, %__MODULE__{} = tree}), do: active_path(tree)
  def active_path({:error, _} = error), do: error
  def active_path(tree = %__MODULE__{}), do: do_active_path(tree, tree.root)

  #-----------------------
  #
  #-----------------------
  defp do_active_path(tree, n, acc \\ [])
  defp do_active_path(_, nil, acc), do: {:ok, Enum.reverse(acc)}
  defp do_active_path(%__MODULE__{} = tree, n, acc) do
    unless n in acc do
      do_active_path(tree, tree.selection[n], [n | acc])
    else
      {:error, {:cyclical_path, n}}
    end
  end

  #---------------------
  #
  #---------------------
  def set_path(tree, target, to)
  def set_path({:ok, %__MODULE__{} = tree}, target, to), do: set_path(tree, target, to)
  def set_path({:error, _} = error, _, _), do: error
  def set_path(%__MODULE__{} = tree, target, to) do
    target = case target do
      %GenAI.Node{id: id} -> id
      x -> x
    end
    select = case to do
      %GenAI.Node{id: id} -> id
      x -> x
    end

    # verify is child
    n = tree.nodes[target]
    t = tree.nodes[select]
    cond do
      is_nil(n) -> {:error, {:target, :not_found}}
      is_nil(t) -> {:error, {:to, :not_found}}
      :else ->
        tree = tree
               |> put_in([Access.key(:selection), n], select)
               |> update_in([Access.key(:nodes), n, Access.key(:children)], & MapSet.put(&1, select))
               |> then(& if target in &1.path, do: %{&1| path: active_path(&1)}, else: &1)
        {:ok, tree}
    end
  end

  #---------------------
  # update_handles
  #---------------------
  defp update_handles(tree, %{handle: nil}), do: tree
  defp update_handles(tree, %{id: id, handle: handle}) do
    put_in(tree, [Access.key(:handles), handle], id)
  end

  #---------------------
  # append_node
  #---------------------
  def append_node(tree, node)
  def append_node({:ok, %__MODULE__{} = tree}, node), do: append_node(tree, node)
  def append_node({:error, _} = error, _), do: error
  def append_node(%__MODULE__{root: nil} = tree, node) do
    tree = %__MODULE__{root: node.id}
           |> put_in([Access.key(:nodes), node.id], node)
           |> put_in([Access.key(:path)], [node.id])
           |> update_handles(node)
    {:ok, tree}
  end
  def append_node(%__MODULE__{} = tree, node) do
    t = Enum.at(tree.path, -1)
    tree = tree
           |> put_in([Access.key(:nodes), node.id], node)
           |> update_in([Access.key(:nodes), t, Access.key(:children)], & MapSet.put(&1, node.id))
           |> put_in([Access.key(:selection), t], node.id)
           |> put_in([Access.key(:path)], tree.path ++ [node.id])
           |> update_handles(node)
    {:ok, tree}
  end


  #---------------------
  # append_nodes
  #---------------------
  def append_nodes(%__MODULE__{} = tree, nodes) do
    # todo insert all at once and update selection/path
    Enum.reduce(nodes, {:ok, tree}, fn(node, tree) ->
      append_node(tree, nodes)
    end)
  end

  #---------------------
  # insert_node
  #---------------------
  def insert_node(tree, target, node)
  def insert_node({:ok, %__MODULE__{} = tree}, target, node), do: insert_node(tree, target, node)
  def insert_node({:error, _} = error, _, _), do: error
  def insert_node(%__MODULE__{} = tree, target, node) do
    target = case target do
      %GenAI.Node{id: id} -> id
      x -> x
    end
    next = tree.selection[target]
    if tree.nodes[target] do
    tree = tree
           |> put_in([Access.key(:nodes), node.id], node)
           |> update_in([Access.key(:nodes), target, Access.key(:children)], & MapSet.put(&1, node.id))
           |> put_in([Access.key(:selection), target], node.id)
           |> then(& (if target in &1.path, do: %{&1| path: active_path(&1)}, else: &1))
           |> update_handles(node)
    if next do
      tree = tree
      |> update_in([Access.key(:nodes), node.id, Access.key(:children)], & MapSet.put(&1, next))
      |> put_in([Access.key(:selection), node.id], next)
      {:ok, tree}
    else
      {:ok, tree}
    end
    else
      {:error, {:target, :not_found}}
    end
  end
end

defmodule GenAI.Setting do
  @vsn 1.0

  defstruct [
    setting: nil,
    value: nil,
    vsn: @vsn
  ]
end



defmodule GenAI.ChatNew do
  @vsn 1.0

  defstruct [
    tree: %GenAI.Tree{},
    vsn: @vsn
  ]

  def to_list(this = %__MODULE__{}) do
    GenAI.Tree.to_list(this.tree)
  end
  def active_path(this  = %__MODULE__{}) do
    GenAI.Tree.active_path(this.tree)
  end
  def set_path(this  = %__MODULE__{}, target, to) do
    with {:ok, tree} <- GenAI.Tree.set_path(this.tree, target, to) do
      {:ok, %{this| tree: tree}}
    end
  end

  def append_node(this, node) do
    with {:ok, tree} <- GenAI.Tree.append_node(this.tree, node) do
      {:ok, %{this| tree: tree}}
    end
  end

  def append_nodes(this, nodes) do
    with {:ok, tree} <- GenAI.Tree.append_nodes(this.tree, nodes) do
      {:ok, %{this| tree: tree}}
    end
  end

  defimpl GenAIProtocol do
    @moduledoc """
    Implements the `GenAIProtocol` for `GenAI.Chat`.

    This allows chat contexts to be used for configuring and running GenAI interactions.
    """

    def with_model(%GenAI.ChatNew{} = this, model, options ) do
      handle = options[:handle]
      node = GenAI.Node.new(GenAI.MessageBehavior, model, handle: handle)
      GenAI.ChatNew.append_node(this, node)
    end

    def with_tool(this, tool, options ) do
      handle = options[:handle]
      node = GenAI.Node.new(GenAI.ToolBehaviour, tool, handle: handle)
      GenAI.ChatNew.append_node(this, node)
    end

    def with_tool(this, tools, options ) do
      handle = options[:handle]
      content = %GenAI.ToolList{tools: tools}
      node = GenAI.Node.new(GenAI.ToolBehaviour, content, handle: handle)
      GenAI.ChatNew.append_node(this, node)
    end

    def with_api_key(this, provider, api_key, options ) when is_bitstring(api_key) and is_atom(provider) do
      handle = options[:handle]
      content = %GenAI.ApiKey{provider: provider, key: api_key}
      node = GenAI.Node.new(GenAI.ApiKeyBehaviour, content, handle: handle)
      GenAI.ChatNew.append_node(this, node)
    end

    def with_api_org(this, provider, api_org, options ) when is_bitstring(api_org) and is_atom(provider) do
      handle = options[:handle]
      content = %GenAI.ApiOrg{provider: provider, org: api_org}
      node = GenAI.Node.new(GenAI.ApiOrgBehaviour, content, handle: handle)
      GenAI.ChatNew.append_node(this, node)
    end
    def with_setting(this, setting) when is_struct(setting) do
      with_setting(this, setting, nil)
    end
    def with_setting(this, setting, options) when is_struct(setting) do
      handle = options[:handle]
      node = GenAI.Node.new(GenAI.SettingBehaviour, setting, handle)
      GenAI.ChatNew.append_node(this, node)
    end
    def with_setting(this, setting, value), do: with_setting(this, setting, value, nil)
    def with_setting(this, setting, value, options) when is_atom(setting) or is_bitstring(setting) do
      handle = options[:handle]
      content = %GenAI.Setting{setting: setting, value: value}
      node = GenAI.Node.new(GenAI.SettingBehaviour, content, handle)
      GenAI.ChatNew.append_node(this, node)
    end

    def with_safety_setting(this, safety_setting, threshold, options ) do
      handle = options[:handle]
      content = %GenAI.SafetySetting{setting: safety_setting, value: threshold}
      node = GenAI.Node.new(GenAI.SafetySettingBehaviour, content, handle)
      GenAI.ChatNew.append_node(this, node)
    end

    def with_message(this, message, options )
    def with_message({:error, _} = error, _, _), do: error
    def with_message({:ok, this}, message, options), do: with_message(this, message, options)
    def with_message(this, message, options) when is_struct(message) do
      handle = options[:handle] || Map.get(message, :handle)
      node = GenAI.Node.new(GenAI.MessageBehaviour, message, handle)
      GenAI.ChatNew.append_node(this, node)
    end

    def with_messages(this, messages, options ) when is_list(messages) do
       # todo optimize bulk insert
       Enum.reduce(messages, this, fn(message, this) ->
          with_message(this, message, options)
       end)
    end

    def stream(_context, _handler) do
      {:ok, :nyi}
    end

    def tune_prompt(this, handle, options ) do
      node_handle = options[:handle]
      content = %GenAI.PromptTune.Simple{prompt: handle}
      node = GenAI.Node.new(GenAI.MessageMutateBehaviour, content, node_handle)
      GenAI.ChatNew.append_node(this, node)
    end

    def score(this, scorer, options) do
      handle = options[:handle]
      node = GenAI.Node.new(GenAI.ScoreBehavior, scorer, handle)
      GenAI.ChatNew.append_node(this, node)
    end

    def fitness(this, fitness, options)  do
      handle = options[:handle]
      node = GenAI.Node.new(GenAI.FitnessBehavior, fitness, handle)
      GenAI.ChatNew.append_node(this, node)
    end

    def early_stopping(this, sentinel, options) when is_struct(sentinel) do
      handle = options[:handle]
      node = GenAI.Node.new(GenAI.EarlyStopBehavior, sentinel, handle)
      GenAI.ChatNew.append_node(this, node)
    end
    def early_stopping(this, sentinel, options) when is_function(sentinel) do
      handle = options[:handle]
      content = %GenAI.EarlyStopLambda{sentinel: sentinel}
      node = GenAI.Node.new(GenAI.EarlyStopBehavior, sentinel, handle)
      GenAI.ChatNew.append_node(this, node)
    end

    def tag(this, tag, options) do
      handle = tag
      content = %GenAI.Tag{name: tag, options: options}
      node = GenAI.Node.new(GenAI.TagBehaviour, content, handle)
      GenAI.ChatNew.append_node(this, node)
    end

    def loop(this, tag, iterator, options) do
      handle = tag
      to = options[:to] || {:loop_start, tag}
      content = %GenAI.Loop{to: to, iterator: iterator, options: options}
      node = GenAI.Node.new(GenAI.LoopBehaviour, content, handle)
      GenAI.ChatNew.append_node(this, node)
    end


    def execute(this, type, options) do
      {:error, :nyi}
    end

    @doc """
    Runs inference on the chat context.

    This function determines the final settings and model, prepares the messages, and then delegates the actual inference execution to the selected provider's `chat/3` function.
    """
    def run(context) do
      # Logic to pick/determine final set of settings, models, messages, with RAG/summarization.
      model = hd(context.settings.model)
      apply(model.provider, :chat, [context.messages |> Enum.reverse(), context.settings.tools, [{:model, model.model} | (context.settings.hyper_params)]])
    end
  end
end
