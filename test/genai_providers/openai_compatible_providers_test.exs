defmodule GenAI.Provider.OpenAICompatibleProvidersTest do
  @moduledoc """
  Unit coverage for the OpenAI-compatible chat providers Z.AI (Zhipu GLM) and Cerebras:
  config key, model -> provider/encoder wiring, and the chat-completions endpoint path
  (Z.AI overrides to /api/paas/v4/chat/completions; Cerebras uses the OpenAI default).
  Deterministic — no network.
  """
  use ExUnit.Case, async: true

  alias GenAI.Provider.ZAI
  alias GenAI.Provider.Cerebras

  describe "Z.AI" do
    test "config_key is :zai" do
      assert ZAI.config_key() == :zai
    end

    test "model/1 wires provider + encoder" do
      m = ZAI.Models.glm_4_6()
      assert m.model == "glm-4.6"
      assert m.provider == GenAI.Provider.ZAI
      assert m.encoder == GenAI.Provider.ZAI.Encoder
    end

    test "chat endpoint overrides to /api/paas/v4/chat/completions" do
      assert {:ok, {{:post, "https://api.z.ai/api/paas/v4/chat/completions"}, _}} =
               ZAI.Encoder.endpoint(nil, %{}, nil, nil, nil)
    end
  end

  describe "Cerebras" do
    test "config_key is :cerebras" do
      assert Cerebras.config_key() == :cerebras
    end

    test "model/1 wires provider + encoder" do
      m = Cerebras.Models.gpt_oss_120b()
      assert m.model == "gpt-oss-120b"
      assert m.provider == GenAI.Provider.Cerebras
      assert m.encoder == GenAI.Provider.Cerebras.Encoder
    end

    test "chat endpoint uses the OpenAI-default /v1/chat/completions" do
      assert {:ok, {{:post, "https://api.cerebras.ai/v1/chat/completions"}, _}} =
               Cerebras.Encoder.endpoint(nil, %{}, nil, nil, nil)
    end
  end
end
