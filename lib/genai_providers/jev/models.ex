defmodule GenAI.Provider.Jev.Models do
  @moduledoc "Hosted classifier model constructors; aliases and immutable version IDs remain distinct."
  def model(name) when is_binary(name),
    do: %GenAI.Model{model: name, provider: GenAI.Provider.Jev}

  def latest, do: model("jev-latest")
  def preview, do: model("jev-preview")
  def list(options \\ []), do: GenAI.Provider.Jev.models(options)

  @doc "Normalize TypeSafe's models[] name catalog, which is not an OpenAI data[] catalog."
  def from_catalog(%{"models" => entries}) when is_list(entries) do
    GenAI.Classifier.Validation.collect(entries, fn
      %{"name" => name} when is_binary(name) and name != "" -> {:ok, model(name)}
      _ -> {:error, :invalid_jev_model_catalog}
    end)
  end

  def from_catalog(_), do: {:error, :invalid_jev_model_catalog}
end
