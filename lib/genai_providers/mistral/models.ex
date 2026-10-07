defmodule GenAI.Provider.Mistral.Models do
  @moduledoc """
  Defines some common Mistral models.
  """

  # <REMOVED UUID HERE> model :: auto-generated pointer for public function model
  def model(model) do
    %GenAI.Model{
      model: model,
      provider: GenAI.Provider.Mistral,
      encoder: GenAI.Provider.Mistral.Encoder
    }
  end

  # --------------------------
  #
  # --------------------------
  # <REMOVED UUID HERE> mistral_small :: auto-generated pointer for public function mistral_small
  def mistral_small(), do: model("mistral-small-latest")

  # --------------------------
  #
  # --------------------------
  # <REMOVED UUID HERE> mistral_medium :: auto-generated pointer for public function mistral_medium
  def mistral_medium(), do: model("mistral-medium-latest")

  # --------------------------
  #
  # --------------------------
  # <REMOVED UUID HERE> mistral_large :: auto-generated pointer for public function mistral_large
  def mistral_large(), do: model("mistral-large-latest")

  # --------------------------
  #
  # --------------------------
  # <REMOVED UUID HERE> codestral :: auto-generated pointer for public function codestral
  def codestral(), do: model("codestral-latest")

  # --------------------------
  #
  # --------------------------
  # <REMOVED UUID HERE> pixtral :: auto-generated pointer for public function pixtral
  def pixtral(), do: model("pixtral-large-latest")

  # --------------------------
  #
  # --------------------------
  # <REMOVED UUID HERE> magistral_medium :: auto-generated pointer for public function magistral_medium
  def magistral_medium(), do: model("magistral-medium-latest")

  # <REMOVED UUID HERE> magistral_small :: auto-generated pointer for public function magistral_small
  def magistral_small(), do: model("magistral-small-latest")

  # --------------------------
  #
  # --------------------------
  # <REMOVED UUID HERE> mistral_saba :: auto-generated pointer for public function mistral_saba
  def mistral_saba(), do: model("mistral-saba-latest")

  # --------------------------
  #
  # --------------------------
  # <REMOVED UUID HERE> ministral_3b :: auto-generated pointer for public function ministral_3b
  def ministral_3b(), do: model("ministral-3b-latest")

  # <REMOVED UUID HERE> ministral_8b :: auto-generated pointer for public function ministral_8b
  def ministral_8b(), do: model("ministral-8b-latest")
end
