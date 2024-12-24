#===============================================================================
# Copyright (c) 2024, Noizu Labs, Inc.
#===============================================================================

defmodule GenAI.Flow.Link.DefaultImplementation do
  require GenAI.Flow.Records
  alias GenAI.Flow.Records, as: R
  alias GenAI.Flow.Types, as: T

  # Default Implementations
  #========================================
  # id/1
  #========================================
  @spec id(T.flow_link) :: T.result(T.link_id, {:id, :blank})
  def id(%{id: nil}), do: {:error, {:id, :blank}}
  def id(%{id: id}), do: {:ok, id}

  def source(%{source: nil}), do: {:error, {:source, :blank}}
  def source(%{source: source = R.link_source()}), do: {:ok, source}
  def source(%{source: _}), do: {:error, {:source, :invalid}}

  def target(%{target: nil}), do: {:error, {:target, :blank}}
  def target(%{target: target = R.link_target()}), do: {:ok, target}
  def target(%{target: _}), do: {:error, {:target, :invalid}}



end