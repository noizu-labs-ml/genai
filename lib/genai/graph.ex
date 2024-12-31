defmodule GenAI.Graph do
  @vsn 1.0
  @moduledoc false

  alias GenAI.Types, as: T
  alias GenAI.Graph.Types, as: G

  @type t :: %__MODULE__{
               id: G.graph_id,
               handle: T.handle,
               name: T.name,
               description: T.description,

               nodes: %{ G.graph_node_id => G.graph_node },
               node_handles: %{ T.handle => G.graph_node_id },

               links: %{ G.graph_link_id => G.graph_link },
               link_handles: %{ T.handle => G.graph_link_id },

               head: G.graph_node_id | nil,
               last_node: G.graph_node_id | nil,
               last_link: G.graph_link_id | nil,




               vsn: float()
             }

  defstruct [
    id: nil,
    handle: nil,

    name: nil,
    description: nil,

    nodes: %{},
    node_handles: %{},
    links: %{},
    link_handles: %{},

    head: nil,
    last_node: nil,
    last_link: nil,

    settings: nil,

    vsn: @vsn
  ]

  def setting(%__MODULE__{settings: settings}, setting, options, default \\ nil) do
    x = options[setting]
    cond do
      is_nil(x) or x == :default ->
        x = settings[setting]
        cond do
          x == nil -> default
          :else -> x
        end
      :else -> x
    end
  end

end


defimpl GenAI.GraphProtocol, for: GenAI.Graph do
  require GenAI.Graph.Types
  alias GenAI.Graph.Types, as: G
  require GenAI.Graph.Link.Records
  alias GenAI.Graph.Link.Records, as: R

  #-------------------------
  # id/1
  #-------------------------
  def id(graph)
  def id(%GenAI.Graph{id: nil}), do: {:error, {:id, :is_nil}}
  def id(%GenAI.Graph{id: id}), do: {:ok, id}

  #-------------------------
  # handle/1
  #-------------------------
  def handle(graph)
  def handle(%GenAI.Graph{handle: nil}), do: {:error, {:handle, :is_nil}}
  def handle(%GenAI.Graph{handle: handle}), do: {:ok, handle}

  #-------------------------
  # handle/2
  #-------------------------
  def handle(graph, default)
  def handle(%GenAI.Graph{handle: nil}, default), do: {:ok, default}
  def handle(%GenAI.Graph{handle: handle}, _), do: {:ok, handle}

  #-------------------------
  # name/1
  #-------------------------
  def name(graph)
  def name(%GenAI.Graph{name: nil}), do: {:error, {:name, :is_nil}}
  def name(%GenAI.Graph{name: name}), do: {:ok, name}

  #-------------------------
  # name/2
  #-------------------------
  def name(graph, default)
  def name(%GenAI.Graph{name: nil}, default), do: {:ok, default}
  def name(%GenAI.Graph{name: name}, _), do: {:ok, name}


  #-------------------------
  # description/1
  #-------------------------
  def description(graph)
  def description(%GenAI.Graph{description: nil}), do: {:error, {:description, :is_nil}}
  def description(%GenAI.Graph{description: description}), do: {:ok, description}

  #-------------------------
  # description/2
  #-------------------------
  def description(graph, default)
  def description(%GenAI.Graph{description: nil}, default), do: {:ok, default}
  def description(%GenAI.Graph{description: description}, _), do: {:ok, description}

  #-------------------------
  # node/2
  #-------------------------
  def node(graph, graph_node)
  def node(graph, graph_node) when G.is_node_id(graph_node) do
    if x = graph.nodes[graph_node] do
      {:ok, x}
    else
      {:error, {:node, :not_found}}
    end
  end
  def node(graph, graph_node) when is_struct(graph_node) do
    with {:ok, id} <- GenAI.Graph.NodeProtocol.id(graph_node) do
      node(graph, id)
    end
  end

  #-------------------------
  # link/2
  #-------------------------
  def link(graph, graph_link)
  def link(graph, graph_link) when G.is_link_id(graph_link) do
    if x = graph.links[graph_link] do
      {:ok, x}
    else
      {:error, {:link, :not_found}}
    end
  end
  def link(graph, graph_link) when is_struct(graph_link) do
    with {:ok, id} <- GenAI.Graph.LinkProtocol.id(graph_link) do
      node(graph, id)
    end
  end

  #-------------------------
  # member?/2
  #-------------------------
  def member?(graph, graph_node)
  def member?(graph, graph_node) when G.is_node_id(graph_node) do
    graph.nodes[graph_node] && true || false
  end
  def member?(graph, graph_node) when is_struct(graph_node) do
    with {:ok, id} <- GenAI.Graph.NodeProtocol.id(graph_node) do
      member?(graph, id)
    end
  end

  #-------------------------
  # by_handle/2
  #-------------------------
  def by_handle(graph, handle)
  def by_handle(graph, handle) do
    if x = graph.node_handles[handle] do
      node(graph, x)
    else
      {:error, {:handle, :not_found}}
    end
  end

  #-------------------------
  # link_by_handle/2
  #-------------------------
  def link_by_handle(graph, handle)
  def link_by_handle(graph, handle) do
    if x = graph.link_handles[handle] do
      link(graph, x)
    else
      {:error, {:handle, :not_found}}
    end
  end

  #-------------------------
  # head/1
  #-------------------------
  def head(graph)
  def head(%GenAI.Graph{head: nil}), do: {:error, {:head, :is_nil}}
  def head(%GenAI.Graph{head: x} = graph), do: node(graph, x)

  #-------------------------
  # last_node/1
  #-------------------------
  def last_node(graph)
  def last_node(%GenAI.Graph{last_node: nil}), do: {:error, {:last_node, :is_nil}}
  def last_node(%GenAI.Graph{last_node: x} = graph), do: node(graph, x)

  #-------------------------
  # last_link/1
  #-------------------------
  def last_link(graph)
  def last_link(%GenAI.Graph{last_link: nil}), do: {:error, {:last_link, :is_nil}}
  def last_link(%GenAI.Graph{last_link: x} = graph), do: link(graph, x)


  defp attempt_set_handle(graph, id, node) do
    with {:ok, handle} <- GenAI.Graph.NodeProtocol.handle(node) do
      if graph.node_handles[handle] do
        raise GenAI.Graph.Exception,
              message: "Node with handle #{handle} already defined in graph",
              details: {:handle_exists, handle}
      end
      graph
      |> put_in([Access.key(:node_handles), handle], id)
    else
      _ -> graph
    end
  end

  defp attempt_set_head(graph, id, _node, options) do
    if GenAI.Graph.setting(graph, :auto_head, options, false) do
      graph
      |> update_in([Access.key(:head)], & &1 || id)
    else
      graph
    end
  end

  defp attempt_set_last_node(graph, id, _node, options) do
    if GenAI.Graph.setting(graph, :update_last, options, false) do
      graph
      |> put_in([Access.key(:last_node)], id)
    else
      graph
    end
  end

  defp auto_link_setting(graph, options) do
    case options[:link] do
      false -> false
      nil -> graph.settings[:auto_link] || false
      :default -> graph.settings[:auto_link] || false
      true -> graph.settings[:auto_link] || true
      {:template, template} ->
        if x = graph.settings[:auto_link_templates][template] do
          x
        else
          raise GenAI.Graph.Exception,
                message: "Auto Link Template #{inspect template} Not Found",
                details: {:template_not_found, template}
        end
      x -> x
    end
  end

  defp attempt_auto_link(graph, from_node, node_id, _node, options) do
    auto_link = auto_link_setting(graph, options)
    cond do
      auto_link == false ->
        graph
      auto_link == true ->
        link = GenAI.Graph.Link.new(from_node, node_id)
        graph
        |> GenAI.GraphProtocol.add_link(link, options)
      GenAI.Graph.LinkProtocol.impl_for(auto_link) ->
        link = auto_link
        with {:ok, link} <- GenAI.Graph.LinkProtocol.putnew_source(link, from_node),
             {:ok, link} <- GenAI.Graph.LinkProtocol.putnew_target(link, node_id),
             {:ok, link} <- GenAI.Graph.LinkProtocol.with_id(link) do
          graph
          |> GenAI.GraphProtocol.add_link(link,  options)
        else
          {:error, details} ->
            raise GenAI.Graph.Exception,
                  message: "Auto Link Failed",
                  details: details
        end
    not(is_struct(auto_link)) and (is_map(auto_link) or is_list(auto_link)) ->
      auto_link_options = auto_link
      link = GenAI.Graph.Link.new(from_node, node_id, auto_link_options)
      graph
      |> GenAI.GraphProtocol.add_link(link, options)
    end
  end

  def attempt_set_node(graph, node_id, graph_node, _options) do
    unless member?(graph, node_id) do
      graph
      |> put_in([Access.key(:nodes), node_id], graph_node)
      else
        raise GenAI.Graph.Exception,
              message: "Node with #{node_id} already defined in graph",
              details: {:node_exists, node_id}
    end
  end


  #-------------------------
  # with_id/1
  #-------------------------
  def with_id(graph) do
    cond do
      graph.id == nil ->
        graph
        |> put_in([Access.key(:id)], UUID.uuid4())
      graph.id == :auto ->
        graph
        |> put_in([Access.key(:id)], UUID.uuid4())
      :else -> graph
    end
    |> then(& {:ok, &1})
  end

  #-------------------------
  # add_link/2
  #-----

  #-------------------------
  # add_node/2
  #-------------------------
  def add_node(graph, graph_node), do: add_node(graph, graph_node, nil)

  #-------------------------
  # add_node/3
  #-------------------------
  def add_node(graph, graph_node, options)
  def add_node(graph, graph_node, options) do
    with {:ok, node_id} <- GenAI.Graph.NodeProtocol.id(graph_node) do
      graph
      |> attempt_set_node(node_id, graph_node, options)
      |> attempt_set_handle(node_id, graph_node)
      |> attempt_set_head(node_id, graph_node, options)
      |> attempt_set_last_node(node_id, graph_node, options)
      |> attempt_auto_link(graph.last_node, node_id, graph_node, options)
    else
      x -> x
    end
  end


  defp local_reference?(source, target) do
    if R.connector(source, :external) && R.connector(target, :external) do
      false
    else
      true
    end
  end

  #-------------------------
  # add_node/3
  #-------------------------
  def add_link(graph, graph_link, options) do
    with {:ok, link_id} <- GenAI.Graph.LinkProtocol.id(graph_link),
         {:ok, source} <- GenAI.Graph.LinkProtocol.source_connector(graph_link),
         {:ok, target} <- GenAI.Graph.LinkProtocol.target_connector(graph_link),
         true <- local_reference?(source, target) || {:error, {:link, :local_reference_required}} do

      graph
      |> attempt_set_link(link_id, graph_link, options)
      |> attempt_set_last_link(link_id, graph_link, options)
      |> attempt_register_link(source, graph_link, options)
      |> attempt_register_link(target, graph_link, options)
      else
        {:error, details} ->
          raise GenAI.Graph.Exception,
                message: "Link Failure - #{inspect details}",
                details: details
    end
  end


  defp attempt_set_link(graph, link_id, graph_link, _options) do
    unless Map.has_key?(graph.links, link_id) do
      graph
      |> put_in([Access.key(:links), link_id], graph_link)
    else
      raise GenAI.Graph.Exception,
            message: "Link with #{link_id} already defined in graph",
            details: {:link_exists, link_id}
    end
  end

  defp attempt_set_last_link(graph, link_id, _graph_link, options) do
    if GenAI.Graph.setting(graph, :update_last_link, options, false) do
      graph
      |> put_in([Access.key(:last_link)], link_id)
    else
      graph
    end
  end

  defp attempt_register_link(graph, connector, link, options) do
    connector_node_id = R.connector(connector, :node)
    cond do
      R.connector(connector, :external) -> graph
      member?(graph, connector_node_id) ->
        n = graph.nodes[connector_node_id]
        {:ok, n} = GenAI.Graph.NodeProtocol.register_link(n, graph, link, options)
        graph
        |> put_in([Access.key(:nodes), connector_node_id], n)
      :else ->
        raise GenAI.Graph.Exception,
              message: "Node Not Found",
              details: {:source_not_found, connector}
    end
  end


end