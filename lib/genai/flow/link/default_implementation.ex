#===============================================================================
# Copyright (c) 2024, Noizu Labs, Inc.
#===============================================================================

defmodule GenAI.Flow.Link.DefaultImplementation do
  require GenAI.Flow.Records
  require GenAI.Flow.Types
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

  def bind_source(flow, value)
  def bind_source(flow, value) when T.is_node_id(value) do
    # only bind if source is set to {:unbound} or nil
    cond do
      flow.source && R.link_source(flow.source, :id) in [nil, {:unbound}]->
        x = update_in(flow, [Access.key(:source)], & &1 && R.link_source(&1, id: value) || R.link_source(id: value))
        {:ok, x}
      :else ->
        {:error, {:source, :already_bound}}
    end
  end
  def bind_source(flow, value = R.link_source()) do
    cond do
      flow.source && R.link_source(flow.source, :id) in [nil, {:unbound}] ->
        x = put_in(flow, [Access.key(:source)], value)
        {:ok, x}
      not(flow.source) ->
        x = put_in(flow, [Access.key(:source)], value)
        {:ok, x}
      :else ->
        {:error, {:source, :already_bound}}
    end
  end

  def bind_target(flow, value)
  def bind_target(flow, value) when T.is_node_id(value) do
    # only bind if target is set to {:unbound} or nil
    cond do
      flow.target && R.link_target(flow.target, :id) in [nil, {:unbound}] ->
        x = update_in(flow, [Access.key(:target)], & &1 && R.link_target(&1, id: value) || R.link_target(id: value))
        {:ok, x}
      :else ->
        {:error, {:target, :already_bound}}
    end
  end
  def bind_target(flow, value = R.link_target()) do
    cond do
      flow.target && R.link_source(flow.target, :id) in [nil, {:unbound}] ->
        x = put_in(flow, [Access.key(:target)], value)
        {:ok, x}
      not(flow.target) ->
        x = put_in(flow, [Access.key(:target)], value)
        {:ok, x}
      :else ->
        {:error, {:target, :already_bound}}
    end
  end

  #========================================
  # with_id/1 (Default)
  #========================================
  @spec with_id(T.flow_link) :: T.result(T.flow_link, T.details)
  def with_id(link) do
    link = update_in(link, [Access.key(:id)], & &1 != :auto && &1  || UUID.uuid4())
    {:ok, link}
  end


end