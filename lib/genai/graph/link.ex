defmodule GenAI.Graph.Link do
  @vsn 1.0
  @moduledoc false

  alias GenAI.Types, as: T
  alias GenAI.Graph.Types, as: G

  @type t :: %__MODULE__{
               id: G.graph_id,
               handle: T.handle,
               name: T.name,
               description: T.description,

               vsn: float()
             }

  defstruct [
    id: nil,
    handle: nil,
    name: nil,
    description: nil,





    vsn: @vsn
  ]
end