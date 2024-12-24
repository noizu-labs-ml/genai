#===============================================================================
# Copyright (c) 2024, Noizu Labs, Inc.
#===============================================================================

defmodule GenAI.Flow.Types do


  @typedoc """
  Flow node identifier.
  """
  @type node_id :: atom | tuple | integer |  bitstring | binary

  @typedoc """
  Flow node alias/handle.
  """
  @type node_handle :: atom | tuple | bitstring

  @typedoc """
  Link identifier.
  """
  @type link_id :: atom | tuple | integer |bitstring | binary

  @typedoc """
  Link inlet/outlet (group)
  """
  @type link_inlet_outlet :: atom | tuple



  @type standard_arrow :: :"<--" | :"-->" | :"<->" | :"---"
  @type fat_arrow :: :"<==" | :"==>" | :"<=>" | :"==="
  @type dashed_arrow :: :"<-.-" | :"-.->" | :"<-.->" | :"-.-"

  @typedoc """
  Link arrow type
  """
  @type link_arrow :: standard_arrow | fat_arrow | dashed_arrow

  @typedoc """
  Link color
  """
  @type link_color :: atom | tuple

  @typedoc """
  Link type
  """
  @type link_type :: :flow | :note | atom

  @typedoc """
  Link label
  """
  @type link_label :: atom | tuple | bitstring

  @typedoc """
  Option list
  """
  @type opts :: nil | keyword()
  @typedoc """
  Option list
  """
  @type options :: keyword() | map() | nil

  @typedoc """
  Flow Structure
  """
  @type flow :: struct() # GenAI.Flow.t

  @typedoc """
  Flow node
  """
  @type flow_node :: struct()

  @typedoc """
  Error details
  """
  @type details :: tuple | atom | bitstring()

  @typedoc """
  Success Response
  """
  @type ok(r) :: {:ok, r}
  @typedoc """
  Error Response
  """
  @type error(e) :: {:error, e}

  @typedoc """
  Call outcome tuple.
  """
  @type result(r,e) :: ok(r) | error(e)


  @type flow_link :: struct()
  @type flow_links :: list(flow_link)
  @type flow_link_map :: %{link_inlet_outlet :: link_id => %{node_id => link}}

  @type link :: flow_link
  @type links :: flow_links
  @type link_map :: flow_link_map

  #
#
#  @typedoc """
#  Edge identifier
#  """
#  @type edge_id :: link_id
#
#  @typedoc """
#
#  """
#  @type edge :: struct()
#
#  @typedoc """
#
#  """
#  @type edges :: list(edge)
#
#  @typedoc """
#
#  """
#  @type edge_map :: %{outlet :: term => %{id => edge}}
#
#  @type edge :: struct()
#  @type edges :: list(edge)
#  @type edge_map :: %{outlet :: term => %{id => edge}}
#
#  @type node_state :: any
#  @type flow_state :: any

  @typedoc """
  Struct version number.
  """
  @type vsn :: float


  defguard is_node_id(id) when is_atom(id) or is_integer(id) or is_tuple(id) or is_bitstring(id) or is_binary(id)
  defguard is_link_id(id) when is_atom(id) or is_integer(id) or is_tuple(id) or is_bitstring(id) or is_binary(id)

end