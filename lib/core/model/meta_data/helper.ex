defmodule GenAI.Model.MetaData.Helper do


  #----------------------------
  # genai_priv_dir/0
  #----------------------------
  @doc """
  Return the path to the priv directory for the GenAI application.
  """
  def genai_priv_dir() do
    :code.priv_dir(:genai) |> List.to_string()
  end

  #----------------------------
  # ok_term/1
  #----------------------------
  @doc """
  Wrap response in {:ok, value} tuple.
  """
  def ok_term(value), do: {:ok, value}

  #----------------------------
  # error_term/1
  #----------------------------
  @doc """
  Wrap error outcome in {:error, details} tuple.
  """
  def error_term(details), do: {:error, details}

  #----------------------------
  # unpack_outcome/2
  #----------------------------
  @doc """
  Return value of {:ok, value} outcomes or apply on_error function or return_value for {:error, details} outcome.

  # Examples

  iex> GenAI.Model.MetaData.Helper.unpack_outcome({:ok, :success_value})
  :success_value

  iex> GenAI.Model.MetaData.Helper.unpack_outcome({:error, :error_value})
  {:error, :error_value}

  iex> GenAI.Model.MetaData.Helper.unpack_outcome({:error, :error_value}, nil)
  nil

  iex> GenAI.Model.MetaData.Helper.unpack_outcome({:error, :error_value}, :problem_occurred)
  :problem_occurred

  iex> GenAI.Model.MetaData.Helper.unpack_outcome({:error, :error_value}, & {:oh_no, &1})
  {:oh_no, :error_value}

  """
  def unpack_outcome(outcome, on_error \\ :__echo__)
  def unpack_outcome({:ok, x}, _), do: x
  def unpack_outcome({:error, details} = o, :__echo__), do: {:error, details}
  def unpack_outcome({:error, details} = o, on_error) do
    cond do
      is_function(on_error, 1) -> apply(on_error, [details])
      :else -> on_error
    end
  end


  #----------------------------
  # merge_options/3
  #----------------------------
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
  # format_options/2
  #----------------------------
  defp format_options(options, return_type)
  defp format_options(nil, _), do: nil
  defp format_options(options, :map) when is_list(options), do: Map.new(options)
  defp format_options(options, :list) when is_map(options), do: Map.to_list(options)
  defp format_options(options, _), do: options


  #----------------------------
  # process_outcomes/1
  #----------------------------
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
  # extract_fields/2
  #--------------------------
  def extract_fields(json, fields)
  def extract_fields(json, fields) do
    Enum.map(fields,
      fn
        {field, {aliases, options}} ->
          case extract_field(json, aliases, options) do
            {:ok, x} -> {:ok, {field, x}}
            error -> error
          end
        {field, aliases} ->
          case extract_field(json, aliases) do
            {:ok, x} -> {:ok, {field, x}}
            error -> error
          end
      end
    )
    |> Enum.reject(&is_nil/1)
    |> process_outcomes()
    |> case do
         {:ok, fields} -> {:ok, Enum.into(fields, %{})}
         error -> error
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
  {:ok, :__undefined__}

  iex> GenAI.Model.MetaData.Helper.extract_field(%{alpha: 1, alp_ha: 2}, [:not_in_enum], default: :not_today)
  {:ok, :not_today}

  iex> GenAI.Model.MetaData.Helper.extract_field(%{alpha: 1, alp_ha: 2}, [:not_in_enum], required: true)
  {:error, :required_field}

  """
  def extract_field(json, aliases, options \\ nil)
  def extract_field(json, aliases, options) when is_list(aliases) do
    Enum.find_value(
      aliases,
      :__default__,
      fn
        alias ->
          x = Access.fetch(json, alias)
          unless x == :error, do: x
      end
    )
    |> case do
       :__default__ ->
           cond do
             options[:required] == true or options[:optional] == false ->
               {:error, :required_field}
             :else ->
               with :error <- Access.fetch(options, :default) do
                 {:ok, :__undefined__}
               else
                 {:ok, {:__value__, default}} -> {:ok, default}
                 {:ok, default} when is_function(default, 0) -> {:ok, apply(default, [])}
                 ok -> ok
               end
           end
       x -> x
       end
  end
  def extract_field(json, alias, options), do: extract_field(json, [alias], options)


  #--------------------------
  # has_option?/2
  #--------------------------

  @doc """
  Check if option is set.

  # Examples

  iex> GenAI.Model.MetaData.Helper.has_option?([a: 1], :a)
  true

  iex> GenAI.Model.MetaData.Helper.has_option?(%{a: 1}, :a)
  true

  iex> GenAI.Model.MetaData.Helper.has_option?([a: 1], :not_set)
  false

  iex> GenAI.Model.MetaData.Helper.has_option?(%{a: 1}, :not_set)
  false

  """
  def has_option?(options, option)
  def has_option?(options, option) do
    Access.fetch(options, option) != :error
  end


  #--------------------------
  # get_option/3
  #--------------------------
  @doc """
  Get option value if present, error term if required and not set, or default value if optional

  # Examples

  iex> GenAI.Model.MetaData.Helper.get_option([a: 1], :a)
  {:ok, 1}

  iex> GenAI.Model.MetaData.Helper.get_option(%{a: 1}, :b, some_arg: :value)
  {:error, {:required, {:option, :b}}}

  iex> GenAI.Model.MetaData.Helper.get_option(%{a: 1}, :b, default: :abba)
  {:ok, :abba}

  iex> GenAI.Model.MetaData.Helper.get_option(%{a: 1}, :b, default: :abba, required: true)
  {:error, {:required, {:option, :b}}}

  iex> GenAI.Model.MetaData.Helper.get_option(%{a: 1}, :b, default: :abba, optional: false)
  {:error, {:required, {:option, :b}}}

  iex> GenAI.Model.MetaData.Helper.get_option(%{a: 1}, :b, default: :abba, required: false)
  {:ok, :abba}


  iex> GenAI.Model.MetaData.Helper.get_option(%{a: 1}, :b, default: :abba, optional: true)
  {:ok, :abba}

  """
  def get_option(options, option, args\\ nil) do
      with :error <- Access.fetch(options, option) do
        cond do
          args[:required] == true or args[:optional] == false ->
            {:error, {:required, {:option, option}}}
          :else ->
            with :error <- Access.fetch(args, :default) do
              if (args[:required] == false or args[:optional] == true),
                 do: {:ok, nil},
                 else: {:error, {:required, {:option, option}}}
            else
              {:ok, default} when is_function(default, 0) -> {:ok, apply(default, [])}
              {:ok, default} when is_function(default, 1) -> {:ok, apply(default, [option])}
              {:ok, default} when is_function(default, 2) -> {:ok, apply(default, [option, options])}
              ok -> ok
            end
        end
      end
  end
end
