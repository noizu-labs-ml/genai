

defmodule GenAI.Session.Node.Input do
    @behaviour Access
    require GenAI.Session.Node.Records
    alias GenAI.Session.Node.Records, as: Node
    require GenAI.Graph.Link.Records
    alias GenAI.Graph.Link.Records, as: Link
    require GenAI.Session.Records
    alias GenAI.Session.Records, as: S
    
    
    defstruct [
        values: %{},
        meta: %{}, # ignore keys, etc.
    ]
    
    @impl Access
    def fetch(%__MODULE__{values: values}, key), do: {:ok, values[key]}
    
    @impl Access
    def get_and_update(this = %__MODULE__{values: values, meta: meta}, key, function) do
        current = values[key]
        case function.(current) do
            {get, update} ->
                {get, put_in(this, [Access.key(:values), key], update)}
            :pop ->
                values = Map.delete(values, key)
                meta = Map.delete(meta, key)
                {current, %__MODULE__{this| values: values, meta: meta}}
        end
    end
    
    @impl Access
    def pop(%__MODULE__{values: values, meta: meta} = this, key) do
        current = values[key]
        values = Map.delete(values, key)
        meta = Map.delete(meta, key)
        {current, %__MODULE__{this| values: values, meta: meta}}
    end
    
    
    
    def expand_inputs(values, scope, context, options) do
        {expanded, scope} = Enum.map_reduce(values, scope, & expand_input(&1, &2, context, options))
        expanded = expanded
                   |> List.flatten()
                   |> Enum.reject(&is_nil/1)
        values = expanded
                 |> Enum.map(fn {:meta, {_,_}} -> nil; {k,v} -> {k,v} end)
                 |> Enum.reject(&is_nil/1)
                 |> Map.new()
        
        meta = expanded
                 |> Enum.map(fn {:meta, {k,v}} -> {k,v}; _ -> nil end)
                 |> Enum.reject(&is_nil/1)
                 |> Map.new()
        {:ok, {%__MODULE__{values: values, meta: meta}, scope}}
    end
    
    #-----------------------------------
    # expand_input/4
    #-----------------------------------
    def expand_input(key_value, scope, context, options)
    def expand_input({k, S.data_set(name: n, records: c)}, scope = Node.scope(session_state: ss), context, options) do
        x = fn (generator, state, context, options) ->
            with {:ok, {response, generator}} <- GenAI.DataGeneratorBehaviour.take(c, generator, context, options) do
                {:ok, {response, {generator, state}}}
            end
        end
        {:ok, {response, ss}} = GenAI.Session.State.query_data_generator(ss, n, x, context, options)
        {{k,response}, Node.scope(scope, session_state: ss)}
    end
    def expand_input({k, S.stack(item: i, default: d)}, Node.scope(session_state: ss), _, _) do
        v = if Map.has_key?(ss.stack, i), do: Map.get(ss.stack, i), else: d
        {{k,v}, scope}
    end
    def expand_input({k, S.stack_item_value(item: i, default: d)}, Node.scope(session_state: ss), _, _) do
        i = if is_list(i), do:  i, else: [i]
        v = case get_in(ss.stack, i) do
            nil -> d
            x -> x
        end
        {{k,v}, scope}
    end
    def expand_input({key, value},scope,_,_), do: {nil, scope}
    def expand_input(_,scope,_,_), do: {nil, scope}
end
