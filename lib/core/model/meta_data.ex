defmodule GenAI.Model.MetaData.Provider do
  import GenAI.Model.MetaData.Helper

  defstruct [
    version: nil,
    name: nil,
    models: %{},
  ]

  def extract_segment(segment, options \\ nil)
  def extract_segment(segment, options) do
    version = segment["version"] || options[:metadata_version]
    models = []
    %__MODULE__{
      version: version,
      name: extract_field(segment, ["name"]) |> unpack_outcome(),
      models: :pending
    } |> ok_term()
  end
end


defmodule GenAI.Model.MetaData.Entry do
  import GenAI.Model.MetaData.Helper
  defstruct [
    version: nil,
    providers: %{},
  ]

  def extract_segment(segment, options \\ nil)
  def extract_segment(%{"genai_metadata" => %{"version" => version}} = segment, options) when version in [0.1] do
    {:ok, options} = merge_options(options, [metadata_version: version])
    segment = segment["genai_metadata"]
    segment["providers"] |> IO.inspect(label: "PROVIDERS")
    Enum.map(segment["providers"] || [], & GenAI.Model.MetaData.Provider.extract_segment(&1, options))
    |> process_outcomes()
    |> case do
         {:ok, providers} ->
           %__MODULE__{
             version: version,
             providers: providers
           } |> ok_term()
         x = {:error, _} -> x
       end
  end
end

defmodule GenAI.Model.MetaData do

  def load(options \\ nil)
  def load(_), do: :wip


  @doc """
      load segment from json into appropriate type.
  """
  # @TODO - extensibility mechanism/match register
  def extract_segment(segment, options \\ nil)
  def extract_segment(%{"genai_metadata" => _} = segment, options) do
    GenAI.Model.MetaData.Entry.extract_segment(segment, options)
  end
  def extract_segment(segment, _), do: {:error, {:unsupported_segment, segment}}


end
