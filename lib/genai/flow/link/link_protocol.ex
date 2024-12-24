#===============================================================================
# Copyright (c) 2024, Noizu Labs, Inc.
#===============================================================================

defprotocol GenAI.Flow.LinkProtocol do
  @moduledoc """
  This protocol defines a unified interface for interacting with links in a `GenAI.Flow`.
  """
  alias GenAI.Flow.Types, as: T
  require GenAI.Flow.Records
  alias GenAI.Flow.Records, as: R

  #==================================================================
  # Protocol Methods
  #==================================================================
  @doc """
  Retrieves the unique identifier of a link

  Returns:
    - `{:ok, id}` if an identifier is found.
    - `{:error, details}` if no identifier can be retrieved.
  """
  @spec id(T.flow_link) :: T.result(T.link_id, T.details)
  def id(flow_link)

  @spec source(T.flow_link) :: T.result(R.link_source, T.details)
  def source(flow_link)

  @spec target(T.flow_link) :: T.result(R.link_target, T.details)
  def target(flow_link)


end



defimpl GenAI.Flow.LinkProtocol, for: Any do
  @moduledoc """
  Raises errors for all entities that don't implement or derive this protocol.
  """

  def id(flow_link) when is_struct(flow_link) do
    raise GenAI.Flow.Exception,
          message: "#{flow_link.__struct__} does not implement GenAI.Flow.NodeProtocol. Use @derive GenAI.Flow.NodeProtocol"
  end
  def id(flow_link) do
    raise GenAI.Flow.Exception,
          message: "#{inspect(flow_link)} does not implement GenAI.Flow.NodeProtocol. Use @derive GenAI.Flow.NodeProtocol"
  end

  def target(flow_link) when is_struct(flow_link) do
    raise GenAI.Flow.Exception,
          message: "#{flow_link.__struct__} does not implement GenAI.Flow.NodeProtocol. Use @derive GenAI.Flow.NodeProtocol"
  end
  def target(flow_link) do
    raise GenAI.Flow.Exception,
          message: "#{inspect(flow_link)} does not implement GenAI.Flow.NodeProtocol. Use @derive GenAI.Flow.NodeProtocol"
  end


  def source(flow_link) when is_struct(flow_link) do
    raise GenAI.Flow.Exception,
          message: "#{flow_link.__struct__} does not implement GenAI.Flow.NodeProtocol. Use @derive GenAI.Flow.NodeProtocol"
  end
  def source(flow_link) do
    raise GenAI.Flow.Exception,
          message: "#{inspect(flow_link)} does not implement GenAI.Flow.NodeProtocol. Use @derive GenAI.Flow.NodeProtocol"
  end



  defmacro __deriving__(module, _struct, _opts) do
    quote do
      defimpl GenAI.Flow.LinkProtocol, for: unquote(module) do
        def id(flow_link) do
          apply(unquote(module), :id, [flow_link])
        end

        def target(flow_link) do
          apply(unquote(module), :target, [flow_link])
        end

        def source(flow_link) do
          apply(unquote(module), :source, [flow_link])
        end

      end
    end
  end
end