
defprotocol GenAI.Flow.NodeProtocol do
  def id(node)
  def add_link(node, link)
end # end of GenAI.Flow.NodeProtocol

defimpl GenAI.Flow.NodeProtocol, for: Any do
  def id(node)
  def id(node) when is_struct(node) do
    raise GenAI.Flow.Exception,
          message: "#{node.__struct__} does not implement GenAI.Flow.NodeProtocol. Use @derive GenAI.Flow.NodeProtocol"
  end
  def id(node) do
    raise GenAI.Flow.Exception,
          message: "#{node} does not implement GenAI.Flow.NodeProtocol. Use @derive GenAI.Flow.NodeProtocol"
  end

  def add_link(node, link)
  def add_link(node, _link) when is_struct(node) do
    raise GenAI.Flow.Exception,
          message: "#{node.__struct__} does not implement GenAI.Flow.NodeProtocol. Use @derive GenAI.Flow.NodeProtocol"
  end
  def add_link(node, _link) do
    raise GenAI.Flow.Exception,
          message: "#{node} does not implement GenAI.Flow.NodeProtocol. Use @derive GenAI.Flow.NodeProtocol"
  end

  defmacro __deriving__(module, _struct, _opts) do
    quote do
      defimpl GenAI.Flow.NodeProtocol, for: unquote(module) do


        def id(node) do
          apply(unquote(module), :id, [node])
        end

        def add_link(node, link) do
          apply(unquote(module), :add_link, [node, link])
        end

      end
    end
  end
end