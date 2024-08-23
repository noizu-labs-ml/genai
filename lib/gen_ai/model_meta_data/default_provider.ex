defmodule GenAI.Model.MetaDataPayload do
  defstruct [
    :version,
    :providers,
  ]
end

defmodule GenAI.Model.MetaDataManager do



  def genai_priv_dir() do
    :code.priv_dir(:genai) |> List.to_string()
  end

  def load_metadata(path, options \\ nil)
  def load_metadata(path, _) do
    YamlElixir.read_all_from_file(path)
  end

  def load(options \\ nil)
  def load(_) do
      {:ok, base} =
        Path.join(genai_priv_dir(), "meta_data")
        |> Path.join("openai.yaml")
        |> load_metadata()
        |> IO.inspect(label: "RAW")
    {:ok, base}
  end

  def extract(data, options) do

  end

end


defmodule GenAI.ModelMetadata.DefaultProvider do

  def get(scope, model, options \\ nil)
  def get(scope, model, _) do
    {:ok,
      %GenAI.Model{
        provider: scope,
        model: model,
        details: %GenAI.Model.Details{}
      }
    }
  end

end
