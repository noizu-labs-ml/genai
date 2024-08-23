defmodule GenAI.Model.MetaData.Model do
  import GenAI.Model.MetaData.Helper

  defstruct [
    version: nil,
    model: nil,
  ]

  def extract_segment(segment, options \\ nil)
  def extract_segment(segment, options) do
    version = segment["version"] || options[:metadata_version]
    %__MODULE__{
      version: version,
      model: extract_field(segment, ["model"]) |> unpack_outcome(),
    } |> ok_term()
  end


  def merge(existing, update, options)
  def merge(nil, update, _), do: {:ok, update}
  def merge(existing, _, _), do: {:ok, existing}
  def merge(existing, update, options) when is_struct(existing, __MODULE__) and is_struct(update, __MODULE__) do
    %__MODULE__{existing|
      version: max(existing.version, update.version),
    } |> ok_term()
  end


end

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
    models = (segment["models"] || [])
             |> Enum.map(& GenAI.Model.MetaData.Model.extract_segment(&1, options))
             |> process_outcomes()

    with {:ok, models} <- models do

      models = Enum.reduce(models, %{}, fn model, acc ->
        with {:ok, merged_model} <- GenAI.Model.MetaData.Model.merge(acc[model.model], model, options) do
          put_in(acc, [Access.key(model.model)], merged_model)
        else
          _ -> acc
        end
      end)

      %__MODULE__{
        version: version,
        name: extract_field(segment, ["name"]) |> unpack_outcome(),
        models: models
      } |> ok_term()

    end
  end

  def merge(existing, update, options)
  def merge(nil, update, _), do: {:ok, update}
  def merge(existing, _, _), do: {:ok, existing}
  def merge(existing, update, options) when is_struct(existing, __MODULE__) and is_struct(update, __MODULE__) do
    models = Enum.reduce(update.models, existing.models, fn {k, v}, acc ->
      with {:ok, model} <- GenAI.Model.MetaData.Model.merge(acc[k], v, options) do
        put_in(acc, [Access.key(k)], model)
      else
        _ -> acc
      end
    end)

    %__MODULE__{existing|
      version: max(existing.version, update.version),
      models: models
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
           providers = Enum.reduce(providers, %{}, fn p, acc ->
             with {:ok, provider} <- GenAI.Model.MetaData.Provider.merge(acc[p.name], p, options) do
               put_in(acc, [Access.key(p.name)], provider)
             else
               _ -> acc
             end
           end)

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
