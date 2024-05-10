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
    iterator: nil,
    options: [],
    vsn: @vsn
  ]
end

defmodule GenAI.LoopClose do
  @vsn 1.0
  defstruct [
    loop_start: nil,
    vsn: @vsn
  ]
end

defmodule GenAI.LoopBehaviour do

end


defmodule GenAI.LoopCloseBehaviour do

end

defmodule GenAI.EarlyStopLambda do
  @vsn 1.0
  defstruct [
    handle: nil,
    sentinel: nil,
    vsn: @vsn
  ]
end


defmodule GenAI.EarlyStopThreshold do
  @vsn 1.0
  defstruct [
    handle: nil,
    threshold: nil, # stop if during loop/epoch score does not improve more than cut off.
    vsn: @vsn
  ]
  def new(threshold) do
    %__MODULE__{
      threshold: threshold
    }
  end
end

defmodule GenAI.EarlyStopDelta do
  @vsn 1.0
  defstruct [
    handle: nil,
    delta: nil, # stop if during loop/epoch score does not improve more than cut off.
    vsn: @vsn
  ]

  def new(delta) do
    %__MODULE__{
      delta: delta
    }
  end
end

defmodule GenAI.EarlyStopBehaviour do

end

defmodule GenAI.Score.Basic do
  @vsn 1.0
  defstruct [
    vsn: @vsn
  ]
end

defmodule GenAI.ScoreBehaviour do

end

defmodule GenAI.Fitness.Basic do
  @vsn 1.0
  defstruct [
    fitness: nil,
    options: nil,
    vsn: @vsn
  ]

  def new(fitness, options) do
    %__MODULE__{
      fitness: fitness,
      options: options
    }
  end

end

defmodule GenAI.FitnessBehaviour do

end

defmodule GenAI.MessageMutateBehaviour do

end

defmodule GenAI.PromptTune.Simple do
  @vsn 1.0
  defstruct [
    handle: nil,
    message: nil,
    options: nil,
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
    # run/execution/loop state specific node state.
    # For static nodes like messages entry will simple be the node itself (actually no entry will be populated and the base entry will be pulled from node list.
    # For dynamic nodes entry will contain current loop/run specific unpacked/generated value.
    # For mutators like prompt tune entry will contain a mutation node with inner contents referencing original effective node.
    # While the original effective node will be stored as a special value where our key will be something like {:mutated, node_guid} rather than just node_guid
    # So that on subsequent loops the underlying value to mutate can be fetched.
    effective_nodes: %{},
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

  def get_node(this, :by_handle, handle) do
    with node_id <- this.handles[handle],
         {:handle, :ok} <- node_id && {:handle, :ok} || {:error, {:handle, handle,  :not_found}},
         node_element <- this.nodes[node_id],
         {:node, :ok} <- node_element && {:node, :ok} || {:error, {:node, node_id, :not_found}} do
         {:ok, node_element}
    end
  end

  def get_node(this, node_id) do
    with node_element <- this.nodes[node_id],
         {:node, :ok} <- node_element && {:node, :ok} || {:error, {:node, node_id, :not_found}} do
      {:ok, node_element}
    end
  end

  def get_effective_node(this, :by_handle, handle) do
    with node_id <- this.handles[handle],
         {:handle, :ok} <- node_id && {:handle, :ok} || {:error, {:handle, handle,  :not_found}},
         node_element <- this.effective_nodes[node_id],
         {:effective_node, :ok} <- node_element && {:effective_node, :ok} || {:error, {:effective_node, node_id, :not_found}} do
      {:ok, node_element}
    end
  end

  def get_effective_node(this, node_id) do
    cond do
      x = this.effective_nodes[node_id] -> {:ok, {:effective_node, x}}
      x = this.nodes[node_id] -> {:ok, {:node, x}}
      :else -> {:error, {:effective_node, node_id, :not_found}}
    end
  end

  def set_effective_node(this, node) do
    # if node is identical to existing node do nothing.
    # otherwise add to effective node entry
    case get_effective_node(this, node.id) do
      {:ok, {:effective_node, ^node}} ->
        {:ok, this}
      {:ok, {:effective_node, x}} ->
        this = put_in(this, [Access.key(:effective_nodes), node.id], node)
        {:ok, this}
      {:ok, {:node, ^node}} ->
        {:ok, this}
      {:ok, {:node, _}} ->
        this = put_in(this, [Access.key(:effective_nodes), node.id], node)
        {:ok, this}
      error -> error
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
      node = GenAI.Node.new(GenAI.ModelBehaviour, model, handle: handle)
      GenAI.ChatNew.append_node(this, node)
    end

    def with_tool(this, tool, options ) do
      handle = options[:handle]
      node = GenAI.Node.new(GenAI.ToolBehaviour, tool, handle: handle)
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

    def tune_prompt(this, tuner, _options) when is_struct(tuner) do
      GenAI.ChatNew.append_node(this, tuner)
    end
    def tune_prompt(this, handle, options ) do
      node_handle = options[:handle]
      content = %GenAI.PromptTune.Simple{message: handle}
      node = GenAI.Node.new(GenAI.MessageMutateBehaviour, content, node_handle)
      GenAI.ChatNew.append_node(this, node)
    end

    def score(this, scorer, options) do
      handle = options[:handle]
      node = GenAI.Node.new(GenAI.ScoreBehaviour, scorer, handle)
      GenAI.ChatNew.append_node(this, node)
    end

    def fitness(this, fitness, options)  when is_struct(fitness) do
      handle = options[:handle] || fitness.handle
      node = GenAI.Node.new(GenAI.FitnessBehaviour, fitness, handle)
      GenAI.ChatNew.append_node(this, node)
    end
    def fitness(this, fitness, options)  do
      handle = options[:handle]
      basic_fitness = GenAI.Fitness.Basic.new(fitness, options)
      node = GenAI.Node.new(GenAI.FitnessBehaviour, basic_fitness, handle)
      GenAI.ChatNew.append_node(this, node)
    end

    def early_stopping(this, sentinel, options) when is_float(sentinel) do
      handle = options[:handle]
      content = %GenAI.EarlyStopDelta{delta: sentinel}
      node = GenAI.Node.new(GenAI.EarlyStopBehaviour, sentinel, handle)
      GenAI.ChatNew.append_node(this, node)
    end
    def early_stopping(this, sentinel, options) when is_struct(sentinel) do
      handle = options[:handle]
      node = GenAI.Node.new(GenAI.EarlyStopBehaviour, sentinel, handle)
      GenAI.ChatNew.append_node(this, node)
    end
    def early_stopping(this, sentinel, options) when is_function(sentinel) do
      handle = options[:handle]
      content = %GenAI.EarlyStopLambda{sentinel: sentinel}
      node = GenAI.Node.new(GenAI.EarlyStopBehaviour, sentinel, handle)
      GenAI.ChatNew.append_node(this, node)
    end

    def tag(this, tag, options) do
      handle = tag
      content = %GenAI.Tag{name: tag, options: options}
      node = GenAI.Node.new(GenAI.TagBehaviour, content, handle)
      GenAI.ChatNew.append_node(this, node)
    end

    def loop(this, tag, iterator, options) do
      # @todo tag might be a struct/grid/data-loader, need protocol to extract handle
      tag = tag
      enter_loop_handle = {:loop_start, tag}
      enter_loop_content = %GenAI.Loop{iterator: iterator, options: options}
      enter_node = GenAI.Node.new(GenAI.LoopBehaviour, enter_loop_content, enter_loop_handle)

      exit_loop_handle = {:loop_close, tag}
      exit_loop_content = %GenAI.LoopClose{loop_start: enter_node.id}
      exit_node = GenAI.Node.new(GenAI.LoopCloseBehaviour, exit_loop_content, exit_loop_handle)
      {:ok, {this, {enter_node, exit_node}}}
    end

    def enter_loop(this, node) do
      GenAI.ChatNew.append_node(this, node)
    end

    def exit_loop(this, node) do
      GenAI.ChatNew.append_node(this, node)
    end

    def execute(this, type, options) do
      # context will have loops/grid search elements.
      # we can't simply convert a flat path into a list of messages,
      # we need to traverse up to loop start entries, and collect effective state
      # up to that point. inside of loops we build messages/settings in parallel.

      #  A -> (B) -> C ->D -> E ->(F) -> G -> H - I* -> J** -> Execute
      #            \-- (Iteration)-------/
      # When we enter a loop/grid at B we have an effective list of messages and settings. At B we store this effective list.
      # Inside of the Loop (B) -> (F) additional settings are set, these may be dynamic so we need to call each entry to pick the effective value.
      # Future nodes may result in a specific model etc. being used due to feature requirements of a node. We ignore this until we encounter the requirement however.
      # So we build messages up to that point if inference points are encountered (when chat history needs to be sent) we do with the effective settings up to that point.
      # User must explictly state if they wish to use a specific model if there are inference points (generated messages) prior to I* and J**. (where J** for exampl emight specify a specific model to use.
      # If a specific model is specific at a node like J** that is different than the default used up to that point (and inference points were encountered) then we emit a warning event to callback listeners if any.  (console out by default)

      IO.puts """
      - 1. Get Active Path.
      - 2. Walk over path, calling protocol method to get effective node state/value for each node.
      - 3. Inference Events build efefcetive message list, effective state from nodes only prior to that point in chain.
           Dynamic Prompts, Tune Prompts, Score step, Fitness step, etc.
           - 3.Tangent* Unlike previous approach if we wish to replay a thread with different models/settings if there are interstitial inference steps
             we need to inejec those changes into the stop of the tree.  replace(handle/id, node | (context) -> node) inject(handle, node | nodes | (context) -> [nodes])
             A->(B)->C->D Becomes A->(B')->C->D or A->B->(Injected)->C->D
      - 4. Behind the scenes when loop start nodes are prepped that grab current context effective node state to allow recall on next iteration.
      - 5. Loop exit nodes grab global state details store on effective node state for the close tag, loop start and elements inside loop can reference for fitness checks/early stop etc.
           - 5.a. when loop exit point is a continuation (next iteration) we manipulate the
             effective state of the loop entry node and reset our global state position to id of the loop entry node while resetting effective node states with cached value.
             Early stop events may populate context state settings to early exit current loop.
           - 5.b. When loop exit proceeds on to remaining context we can wipe loop_start state cache and proceed as usual. context state is fed forward so for example after one loop ends,
             and a second loop picks up effective state on exiting the loop becomes the starting effective state in that context. lookup chackes loop.current_iteration_state(head)[value] || context[state][value]
           - 5.c. note When those methods (like score, fitness) are run they use protocol to set context state which in turns
             determines current loop or root context and sets those values into the loop_start node's  current_iteration_state which is referenced to determine when to early exit loop,
             current_iteration_state is appened to previous_iteration_state during each loop so prior values can be referenced as neeed for more complex logic like early stop checks.
             A new head iteration state is added at the start of each loop.
      - 6. Fin. If runing an execute(report) not regular run additional data is retained over each pass, explicitly when score is called, or store() is called the chain of messages leading up to the score
           is tracked which may be a tree A -> B -> [fan out C1 .. CN of loop] -> D -> E -> Score
      """

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
