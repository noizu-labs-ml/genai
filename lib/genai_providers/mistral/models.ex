defmodule GenAI.Provider.Mistral.Models do
  @moduledoc """
  Defines some common Mistral models.
  """

  # ⟦𓈪𓏇𓄓𓈌⟧ model :: auto-generated pointer for public function model
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
  # ⟦𓁫𓎡𓆙𓐘⟧ mistral_small :: auto-generated pointer for public function mistral_small
  def mistral_small(), do: model("mistral-small-latest")

  # --------------------------
  #
  # --------------------------
  # ⟦𓋙𓋆𓁽𓍅⟧ mistral_medium :: auto-generated pointer for public function mistral_medium
  def mistral_medium(), do: model("mistral-medium-latest")

  # --------------------------
  #
  # --------------------------
  # ⟦𓌖𓏜𓋗𓁙⟧ mistral_large :: auto-generated pointer for public function mistral_large
  def mistral_large(), do: model("mistral-large-latest")

  # --------------------------
  #
  # --------------------------
  # ⟦𓈭𓇭𓂰𓂥⟧ codestral :: auto-generated pointer for public function codestral
  def codestral(), do: model("codestral-latest")

  # --------------------------
  #
  # --------------------------
  # ⟦𓇙𓊊𓆏𓁔⟧ pixtral :: auto-generated pointer for public function pixtral
  def pixtral(), do: model("pixtral-large-latest")

  # --------------------------
  #
  # --------------------------
  # ⟦𓐚𓎳𓍬𓏊⟧ magistral_medium :: auto-generated pointer for public function magistral_medium
  def magistral_medium(), do: model("magistral-medium-latest")

  # ⟦𓏔𓀶𓈵𓄬⟧ magistral_small :: auto-generated pointer for public function magistral_small
  def magistral_small(), do: model("magistral-small-latest")

  # --------------------------
  #
  # --------------------------
  # ⟦𓎶𓂀𓏤𓋉⟧ mistral_saba :: auto-generated pointer for public function mistral_saba
  def mistral_saba(), do: model("mistral-saba-latest")

  # --------------------------
  #
  # --------------------------
  # ⟦𓁳𓅈𓀼𓇍⟧ ministral_3b :: auto-generated pointer for public function ministral_3b
  def ministral_3b(), do: model("ministral-3b-latest")

  # ⟦𓌙𓇂𓃾𓃩⟧ ministral_8b :: auto-generated pointer for public function ministral_8b
  def ministral_8b(), do: model("ministral-8b-latest")
end
