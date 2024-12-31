defmodule GenAI.Graph.Types do

  @type graph :: term
  @type graph_id :: term

  @type graph_link :: term
  @type graph_link_id :: term

  @type graph_node :: term
  @type graph_node_id :: term

  defguard is_graph_id(id) when is_atom(id) or is_integer(id) or is_tuple(id) or is_bitstring(id) or is_binary(id)
  defguard is_node_id(id) when is_atom(id) or is_integer(id) or is_tuple(id) or is_bitstring(id) or is_binary(id)
  defguard is_link_id(id) when is_atom(id) or is_integer(id) or is_tuple(id) or is_bitstring(id) or is_binary(id)

end