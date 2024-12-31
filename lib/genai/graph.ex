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
               last: G.graph_node_id | nil,




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
    last: nil,

    vsn: @vsn
  ]
end