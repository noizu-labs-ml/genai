#===============================================================================
# Copyright (c) 2024, Noizu Labs, Inc.
#===============================================================================

defprotocol GenAI.MessageProtocol do
  def stub(message)
end

#defimpl GenAI.MessageProtocol, for Any do
#
#  def stub(entity) when is_struct(entity) do
#    raise GenAI.Flow.Exception,
#          message: "#{entity.__struct__} does not implement GenAI.MessageProtocol"
#  end
#  def stub(entity) do
#    raise GenAI.Flow.Exception,
#          message: "#{inspect(entity)} does not implement GenAI.MessageProtocol"
#  end
#end