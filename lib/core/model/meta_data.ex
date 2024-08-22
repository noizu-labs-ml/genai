defmodule GenAI.Model.MetaData.EntryBehaviour do
  import GenAI.Model.MetaData.Helper


  @type options :: Keyword.t | Map.t | nil

  @doc """
  Index/Key used for maps.
  """
  @callback handle(struct) :: term

  @doc """
  Prepare struct of appropriate type from segment map.
  Extensibility options will provide mechanism to return a type other than default __MODULE__ during extraction.
  """
  @callback extract_segment(json :: Map.t, options) :: {:ok, struct} | {:error, term}

  @doc """
  Extract array of segments into map.
  """
  @callback extract_segments(entries :: list, options) :: {:ok, Map.t} | {:error, term}

  @doc """
  Merge two entries. Note once extensibility option implemented existing and update may be of different types.
  Resolution  logic will be needed to support this such as casting both models to a universal format and then merging
  into appropriate struct. Alternatively A basic approach would be to specify known from type list to determine resulting output struct.
  """
  @callback merge(struct, struct, options) :: {:ok, struct} | {:error, term}


  @doc """
  Merge list of entries into a map.
  """
  @callback merge_list(entries :: list, options) :: {:ok, Map.t} | {:error, list}


  @doc """
  Merge two entry maps together.
  """
  @callback merge_groups(existing :: Map.t, update :: Map.t, options) :: {:ok, Map.t} | {:error, list}




  @doc """
  Default Implementation
  """
  def extract_segments(handler, segments, options) do
    with {:ok, entries} <- segments
                                |> Enum.map(& apply(handler,:extract_segment, [&1, options]))
                                |> process_outcomes() do
      apply(handler, :merge_list, [entries, options])
    end
  end


  @doc """
  Default Implementation
  """
  def merge_list(handler, entries, options) do
    {m,e} = Enum.reduce(entries, {%{}, []}, fn(entry, {acc, errors}) ->
      with {:ok, merged} <- apply(handler, :merge, [acc[apply(handler, :handle, [entry])], entry, options ]) do
        {put_in(acc, [Access.key(apply(handler, :handle, [entry]))], merged), errors}
      else
        {:error, x} -> {acc, [x | errors]}
        _ -> {acc, errors}
      end
    end)
    if e == [], do: {:ok, m}, else: {:error, e}
  end

  @doc """
  Default Implementation
  """
  def merge_groups(handler, existing, update, options) do
    {m,e} = Enum.reduce(
      update,
      {existing, []},
      fn
        {k, v}, {acc, errors} ->
          with {:ok, merged} <- apply(handler, :merge, [acc[k], v, options]) do
            {put_in(acc, [Access.key(k)], merged), errors}
          else
            {:error, x} -> {acc, [x | errors]}
            _ -> {acc, errors}
          end
      end)
    if e == [], do: {:ok, m}, else: {:error, e}
  end


end



defmodule GenAI.Model.MetaData.Model do
  alias GenAI.Model.MetaData.EntryBehaviour

  import GenAI.Model.MetaData.Helper

  @behaviour EntryBehaviour

  defstruct [
    version: nil,
    model: nil,
  ]

  @impl EntryBehaviour
  def handle(entry), do: entry.model

  @impl EntryBehaviour
  def extract_segment(segment, options \\ nil)
  def extract_segment(segment, options) do
    version = segment["version"] || options[:metadata_version]
    %__MODULE__{
      version: version,
      model: extract_field(segment, ["model"]) |> unpack_outcome(),
    } |> ok_term()
  end

  @impl EntryBehaviour
  def extract_segments(segments, options \\ nil)
  def extract_segments(segments, options) do
    EntryBehaviour.extract_segments(__MODULE__, segments, options)
  end

  @impl EntryBehaviour
  def merge(existing, update, options \\ nil)
  def merge(nil, update, _), do: {:ok, update}
  def merge(existing, _, _), do: {:ok, existing}
  def merge(existing, update, options) when is_struct(existing, __MODULE__) and is_struct(update, __MODULE__) do
    %__MODULE__{existing|
      version: max(existing.version, update.version),
    } |> ok_term()
  end

  @impl EntryBehaviour
  def merge_list(entries, options \\ nil)
  def merge_list(entries, options) do
    EntryBehaviour.merge_list(__MODULE__, entries, options)
  end

  @impl EntryBehaviour
  def merge_groups(existing, update, options \\ nil)
  def merge_groups(existing, update, options) do
    EntryBehaviour.merge_groups(__MODULE__, existing, update, options)
  end
end

defmodule GenAI.Model.MetaData.Provider do
  alias GenAI.Model.MetaData.EntryBehaviour

  import GenAI.Model.MetaData.Helper

  @behaviour EntryBehaviour

  defstruct [
    version: nil,
    name: nil,
    models: %{},
  ]

  @impl EntryBehaviour
  def handle(entry), do: entry.name

  @impl EntryBehaviour
  def extract_segment(segment, options \\ nil)
  def extract_segment(segment, options) do
    with {:ok, models} <- (segment["models"] || [])
                          |> GenAI.Model.MetaData.Model.extract_segments(options),
         {:ok, name} <- extract_field(segment, ["name"]) do
      %__MODULE__{
        version: segment["version"] || options[:metadata_version],
        name: name,
        models: models
      } |> ok_term()
    end
  end

  @impl EntryBehaviour
  def merge(existing, update, options \\ nil)
  def merge(nil, update, _), do: {:ok, update}
  def merge(existing, _, _), do: {:ok, existing}
  def merge(existing, update, options) when is_struct(existing, __MODULE__) and is_struct(update, __MODULE__) do
    with {:ok, models} <- GenAI.Model.MetaData.Model.merge_group(existing.models, update.models, options) do
      %__MODULE__{existing|
        version: max(existing.version, update.version),
        models: models
      } |> ok_term()
    end
  end

  @impl EntryBehaviour
  def merge_list(entries, options \\ nil)
  def merge_list(entries, options) do
    EntryBehaviour.merge_list(__MODULE__, entries, options)
  end

  @impl EntryBehaviour
  def merge_groups(existing, update, options \\ nil)
  def merge_groups(existing, update, options) do
    EntryBehaviour.merge_groups(__MODULE__, existing, update, options)
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

    providers = Enum.map(segment["providers"] || [], & GenAI.Model.MetaData.Provider.extract_segment(&1, options))
                |> process_outcomes()




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
