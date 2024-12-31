defmodule GenAI.Helpers do
  @moduledoc """
  A collection of helper functions for GenAI.
  """


  @doc """
  Handle error tuple response.

  ## Examples
    iex> {:ok, :return_me} |> GenAI.Helpers.on_error(:label, :unexpected)
    {:ok, :return_me}

    iex> {:ok, nil} |> GenAI.Helpers.on_error(:label, :unexpected)
    {:ok, nil}

    iex> {:error, :foo} |> GenAI.Helpers.on_error(:return_value, :bar)
    {:ok, :bar}

    iex> {:error, :foo} |> GenAI.Helpers.on_error(:return_error, :bar)
    {:error, :bar}

    iex> {:error, :foo} |> GenAI.Helpers.on_error(:return, :bar)
    :bar

    iex> {:error, :foo} |> GenAI.Helpers.on_error(:call, fn -> :biz end)
    :biz

    iex> {:error, :foo} |> GenAI.Helpers.on_error(:call, fn x -> {:biz, x} end)
    {:biz, {:error, :foo}}

    iex> {:error, :foo} |> GenAI.Helpers.on_error(:label, :wrap)
    {:error, {:wrap, :foo}}
  """
  def on_error(response, action, value)
  def on_error({:ok, _} = response, _, _), do: response
  def on_error({:error, _}, :return_value, value), do: {:ok, value}
  def on_error({:error, _}, :return_error  , value), do: {:error, value}
  def on_error({:error, _}, :return, value), do: value
  def on_error({:error, _}, :call, value) when is_function(value, 0), do: apply(value, [])
  def on_error({:error, _} = response, :call, value) when is_function(value, 1), do: apply(value, [response])
  def on_error({:error, error}, :label, label), do: {:error, {label, error}}

  @doc """
    Handle {:ok, nil} tuple response.
    ## Examples
      iex> {:ok, 5} |> GenAI.Helpers.on_nil(:label, :unexpected)
      {:ok, 5}

      iex> {:ok, nil} |> GenAI.Helpers.on_nil(:return_value, :bar)
      {:ok, :bar}

      iex> {:ok, nil} |> GenAI.Helpers.on_nil(:return_error, :bar)
      {:error, :bar}

      iex> {:ok, nil} |> GenAI.Helpers.on_nil(:return, :bar)
      :bar

      iex> {:ok, nil} |> GenAI.Helpers.on_nil(:call, fn -> :biz end)
      :biz

      iex> {:ok, nil} |> GenAI.Helpers.on_nil(:label, :wrap)
      {:error, {:wrap, :is_nil}}

      iex> {:error, :foo} |> GenAI.Helpers.on_nil(:label, :wrap)
      {:error, :foo}

  """
  def on_nil(response, action, value)
  def on_nil({:ok, nil}, :return_value, value), do: {:ok, value}
  def on_nil({:ok, nil}, :return_error  , value), do: {:error, value}
  def on_nil({:ok, nil}, :return, value), do: value
  def on_nil({:ok, nil}, :call, value) when is_function(value, 0), do: apply(value, [])
  def on_nil({:ok, nil}, :call, value) when is_function(value, 1), do: apply(value, [{:ok, nil}])
  def on_nil({:ok, nil}, :label, label), do: {:error, {label, :is_nil}}
  def on_nil(response, _, _), do: response

end