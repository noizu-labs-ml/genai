defmodule GenAI.Model.MetaData.Helper do

  def genai_priv_dir() do
    :code.priv_dir(:genai) |> List.to_string()
  end

  def ok_term(value), do: {:ok, value}
  def error_term(details), do: {:error, details}

  @doc """
  Return value of {:ok, value} outcomes or apply on_error function or return_value for {:error, details} outcome.

  # Examples

  iex> GenAI.Model.MetaData.Helper.unpack_outcome({:ok, :success_value})
  :success_value

  iex> GenAI.Model.MetaData.Helper.unpack_outcome({:error, :error_value})
  nil

  iex> GenAI.Model.MetaData.Helper.unpack_outcome({:error, :error_value}, :problem_occurred)
  :problem_occurred

  iex> GenAI.Model.MetaData.Helper.unpack_outcome({:error, :error_value}, & {:oh_no, &1})
  {:oh_no, :error_value}

  """
  def unpack_outcome(outcome, on_error \\ nil)
  def unpack_outcome({:ok, x}, _), do: x
  def unpack_outcome({:error, details} = o, on_error) do
    cond do
      is_function(on_error, 1) -> apply(on_error, [details])
      :else -> on_error
    end
  end


  @doc """
  Simple utility method for merging to set of request options.
  Allows for combining keyword list and maps. That data type of the left hand arg will be used unless return_type set.

  # Examples
  iex> GenAI.Model.MetaData.Helper.merge_options(nil, nil)
  {:ok, nil}

  iex> GenAI.Model.MetaData.Helper.merge_options(%{a: 1}, nil)
  {:ok, %{a: 1}}

  iex> GenAI.Model.MetaData.Helper.merge_options(nil, [a: 1])
  {:ok, [{:a, 1}]}

  iex> GenAI.Model.MetaData.Helper.merge_options(%{a: 1}, [a: 2, b: 3])
  {:ok, %{a: 2, b: 3}}

  iex> GenAI.Model.MetaData.Helper.merge_options([a: 5], %{a: 7, b: 2})
  {:ok, [{:a, 7}, {:b, 2}]}

  iex> GenAI.Model.MetaData.Helper.merge_options([a: 5], %{a: 7, b: 2}, :map)
  {:ok, %{a: 7, b: 2}}

  iex> GenAI.Model.MetaData.Helper.merge_options(%{a: 1}, [a: 2, b: 3], :list)
  {:ok, [{:a, 2}, {:b, 3}]}
  """
  def merge_options(lhs, rhs, return_type \\ :auto)
  def merge_options(nil, nil, _), do: {:ok, nil}
  def merge_options(nil, rhs, return_type), do: {:ok, format_options(rhs, return_type)}
  def merge_options(lhs, nil, return_type), do: {:ok, format_options(lhs, return_type)}
  def merge_options(lhs, rhs, return_type) when is_map(lhs) and is_map(rhs) do
    {:ok, Map.merge(lhs, rhs) |> format_options(return_type)}
  end
  def merge_options(lhs, rhs, return_type) when is_list(lhs) and is_list(rhs) do
    {:ok, Keyword.merge(lhs, rhs) |> format_options(return_type)}
  end
  def merge_options(lhs, rhs, return_type) when is_list(lhs) and is_map(rhs) do
    {:ok, Keyword.merge(lhs, Map.to_list(rhs)) |> format_options(return_type)}
  end
  def merge_options(lhs, rhs, return_type) when is_map(lhs) and is_list(rhs) do
    {:ok, Map.merge(lhs, Map.new(rhs)) |> format_options(return_type)}
  end

  #----------------------------
  #
  #----------------------------
  defp format_options(options, return_type)
  defp format_options(nil, _), do: nil
  defp format_options(options, :map) when is_list(options), do: Map.new(options)
  defp format_options(options, :list) when is_map(options), do: Map.to_list(options)
  defp format_options(options, _), do: options


  @doc """
  Process a list of outcomes, returning a tuple with the list of ok items or the list of error details.

  # Examples

  iex> GenAI.Model.MetaData.Helper.process_outcomes([])
  {:ok, []}

  iex> GenAI.Model.MetaData.Helper.process_outcomes([{:ok, 1}, {:ok, 2}])
  {:ok, [1, 2]}

  iex> GenAI.Model.MetaData.Helper.process_outcomes([{:ok, 1}, {:error, :reason}, {:ok, 2}, {:error, :other_reason}])
  {:error, [{:error, :reason}, {:error, :other_reason}]}

  """
  def process_outcomes(outcomes) do
    {oks, errors} = Enum.split_with(outcomes, fn
      {:ok, _} -> true
      {:error, _} -> false
    end)

    if errors == [] do
      items = Enum.map(oks, fn {:ok, item} -> item end)
      {:ok, items}
    else
      {:error, errors}
    end
  end

  #--------------------------
  # extract_field/3
  #--------------------------
  @doc """
  Extract field (by name or list of aliases in order or precedence) from map or keyword list.

  # Examples
  iex> GenAI.Model.MetaData.Helper.extract_field(%{alpha: 1, alp_ha: 2}, :alpha)
  {:ok, 1}

  iex> GenAI.Model.MetaData.Helper.extract_field(%{alpha: 1, alp_ha: 2}, [:alp_ha, :alpha])
  {:ok, 2}

  iex> GenAI.Model.MetaData.Helper.extract_field(%{alpha: 1, alp_ha: 2}, [:not_in_enum])
  {:ok, {:genai, :undefined}}

  """
  def extract_field(json, aliases, default \\ {:genai, :undefined})
  def extract_field(json, aliases, default) when is_map(json) and is_list(aliases) do
    Enum.find_value(
      aliases,
      {:ok, default},
      & (if Map.has_key?(json, &1), do: {:ok, json[&1]})
    )
  end
  def extract_field(json, aliases, default) when is_list(json) and is_list(aliases) do
    Enum.find_value(
      aliases,
      {:ok, default},
      & (if Keyword.has_key?(json, &1), do: {:ok, json[&1]})
    )
  end
  def extract_field(json, alias, default) when is_map(json) do
    cond do
      Map.has_key?(json, alias) -> {:ok, json[alias]}
      :else -> {:ok, default}
    end
  end
  def extract_field(json, alias, default) when is_list(json) do
    cond do
      Keyword.has_key?(json, alias) -> {:ok, json[alias]}
      :else -> {:ok, default}
    end
  end

end
