#
##
##
##defmodule GenAI.MetaDataLoader.Root do
##  defstruct [
##    version: nil,
##    providers: %{},
##  ]
##
##  def load(json, options)
##  def load(json, options) do
##    with {:ok, providers} <- load_providers(json["providers"], options) do
##      segment = %__MODULE__{
##        version: json["version"],
##        providers: providers
##      }
##      {:ok, segment}
##    end
##  end
##
##  def load_providers(providers, options)
##  def load_providers(nil, _), do: {:ok, %{}}
##
##
##  def merge(this, that, options)
##  def merge(this, _, _) do
##    this
##  end
##end
##
##defmodule GenAI.MetaDataLoader.Provider do
##  defstruct [
##    name: nil,
##    models: %{},
##  ]
##
##  def load(json, options)
##  def load(json, _) do
##    segment = %__MODULE__{
##      name: json["name"]
##    }
##    {:ok, segment}
##  end
##
##  def merge(this, that, options)
##  def merge(this, _, _) do
##    this
##  end
##
##end
##
##
##defmodule GenAI.MetaDataLoader do
##  import  GenAI.MetaDataLoader.Common
##  #-------------------------
##  #
##  #-------------------------
##  def genai_priv_dir() do
##    :code.priv_dir(:genai) |> List.to_string()
##  end
##
##  #-------------------------
##  #
##  #-------------------------
##  def load(options \\ nil)
##  def load(options) do
##    config =
##      genai_priv_dir()
##      |> Path.join("meta_data")
##      |> Path.join("open_ai.yaml")
##    with {:ok, raw} <- YamlElixir.read_all_from_file(config) do
##      x = raw
##          |> Enum.map(& load_segment(&1, options))
##      with {:ok, segments} <- list_outcome(x) do
##        merge_segments(segments, options)
##      end
##    end
##  end
##
##  #-------------------------
##  #
##  #-------------------------
##  def load_segment(%{"genai_metadata" => segment}, options) do
##    GenAI.MetaDataLoader.Root.load(segment, options)
##  end
##
##  #-------------------------
##  #
##  #-------------------------
##  def merge_segments([h|t], options) do
##    Enum.reduce_while(t, h,
##      fn(append, acc) ->
##        with {:ok, x} <- acc.__struct__.merge(acc, append, options) do
##          {:cont, x}
##        else
##          error = {:error, _} -> {:halt, error}
##        end
##      end)
##    |> case do
##         x = {:error, _} -> x
##         x -> {:ok, x}
##       end
##  end
##
##
##end
#
#defmodule GenAI.MetaDataLoader.Helper do
#  @doc """
#  Return path to genai library priv folder.
#  """
#  def genai_priv_dir() do
#    :code.priv_dir(:genai) |> List.to_string()
#  end
#
#  @doc """
#  Return value of {:ok, value} outcomes or apply on_error function or return_value for {:error, details} outcome.
#
#  # Examples
#
#  iex> GenAI.MetaDataLoader.Helper.unpack_outcome({:ok, :success_value})
#  :success_value
#
#  iex> GenAI.MetaDataLoader.Helper.unpack_outcome({:error, :error_value})
#  nil
#
#  iex> GenAI.MetaDataLoader.Helper.unpack_outcome({:error, :error_value}, :problem_occurred)
#  :problem_occurred
#
#  iex> GenAI.MetaDataLoader.Helper.unpack_outcome({:error, :error_value}, & {:oh_no, &1})
#  {:oh_no, :error_value}
#
#  """
#  def unpack_outcome(outcome, on_error \\ nil)
#  def unpack_outcome({:ok, x}, _), do: x
#  def unpack_outcome({:error, details} = o, on_error) do
#    cond do
#      is_function(on_error, 1) -> apply(on_error, [details])
#      :else -> on_error
#    end
#  end
#
#  @doc """
#  Process a list of outcomes, returning a tuple with the list of ok items or the list of error details.
#
#  # Examples
#
#  iex> GenAI.MetaDataLoader.Helper.process_outcomes([])
#  {:ok, []}
#
#  iex> GenAI.MetaDataLoader.Helper.process_outcomes([{:ok, 1}, {:ok, 2}])
#  {:ok, [1, 2]}
#
#  iex> GenAI.MetaDataLoader.Helper.process_outcomes([{:ok, 1}, {:error, :reason}, {:ok, 2}, {:error, :other_reason}])
#  {:error, [{:error, :reason}, {:error, :other_reason}]}
#
#  """
#  def process_outcomes(outcomes) do
#    {oks, errors} = Enum.split_with(outcomes, fn
#      {:ok, _} -> true
#      {:error, _} -> false
#    end)
#
#    if errors == [] do
#      items = Enum.map(oks, fn {:ok, item} -> item end)
#      {:ok, items}
#    else
#      {:error, errors}
#    end
#  end
#
#  #--------------------------
#  # extract_field/3
#  #--------------------------
#  @doc """
#  Extract field (by name or list of aliases in order or precedence) from map or keyword list.
#
#  # Examples
#  iex> GenAI.MetaDataLoader.Helper.extract_field(%{alpha: 1, alp_ha: 2}, :alpha)
#  {:ok, 1}
#
#  iex> GenAI.MetaDataLoader.Helper.extract_field(%{alpha: 1, alp_ha: 2}, [:alp_ha, :alpha])
#  {:ok, 2}
#
#  iex> GenAI.MetaDataLoader.Helper.extract_field(%{alpha: 1, alp_ha: 2}, [:not_in_enum])
#  {:ok, {:genai, :undefined}}
#
#  """
#  def extract_field(json, aliases, default \\ {:genai, :undefined})
#  def extract_field(json, aliases, default) when is_map(json) and is_list(aliases) do
#    Enum.find_value(
#      aliases,
#      {:ok, default},
#      & (if Map.has_key?(json, &1), do: {:ok, json[&1]})
#    )
#  end
#  def extract_field(json, aliases, default) when is_list(json) and is_list(aliases) do
#    Enum.find_value(
#      aliases,
#      {:ok, default},
#      & (if Keyword.has_key?(json, &1), do: {:ok, json[&1]})
#    )
#  end
#  def extract_field(json, alias, default) when is_map(json) do
#    cond do
#      Map.has_key?(json, alias) -> {:ok, json[alias]}
#      :else -> {:ok, default}
#    end
#  end
#  def extract_field(json, alias, default) when is_list(json) do
#    cond do
#      Keyword.has_key?(json, alias) -> {:ok, json[alias]}
#      :else -> {:ok, default}
#    end
#  end
#
#end
#
#
#defmodule GenAI.MetaDataLoader.Capacity do
#  import GenAI.MetaDataLoader.Helper
#  defstruct [
#    requests_per_minute: nil,
#    request_per_day: nil,
#    tokens_per_minute: nil,
#    batch_queue_limit: nil,
#    context_window: nil,
#    max_output_tokens: nil,
#    vram: nil,
#  ]
#
#  def extract(json, options)
#  def extract(json, options) do
##    x = %__MODULE__{
##    #req
##    }
#:wip
#  end
#
#
#
#
#
#end
#
#defmodule GenAI.MetaDataLoader do
#  def load(options \\ nil)
#  def load(_), do: :wip
#end
