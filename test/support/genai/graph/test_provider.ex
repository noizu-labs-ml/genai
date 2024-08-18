defmodule GenAI.Provider.TestProvider do

  defmodule Models do
    def test_model() do
      %GenAI.Model{
        provider: GenAI.Provider.TestProvider,
        model: :test_model,
        vsn: 1.0
      }
    end
  end

end