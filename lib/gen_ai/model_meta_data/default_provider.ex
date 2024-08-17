defmodule GenAI.ModelMetadata.DefaultProvider do

  def get(scope, model, options \\ nil)
  def get(scope, model, _) do
    {:ok,
      %GenAI.Model{
        provider: scope,
        model: model,
        details: %GenAI.ModelDetails{}
      }
    }
  end

end
